import Foundation
import TonAPI
import TonSwift
import BigInt
import OpenAPIRuntime

struct API {
  private let tonAPIClient: TonAPI.Client
  
  init(tonAPIClient: TonAPI.Client) {
    self.tonAPIClient = tonAPIClient
  }
}

// MARK: - Account

extension API {
  func getAccountInfo(address: String) async throws -> Account {
    let response = try await tonAPIClient
      .getAccount(.init(path: .init(account_id: address)))
    return try Account(account: try response.ok.body.json)
  }
  
  func getAccountJettonsBalances(address: Address) async throws -> [JettonBalance] {
    let response = try await tonAPIClient
      .getAccountJettonsBalances(path: .init(account_id: address.toRaw()))
    return try response.ok.body.json.balances
      .compactMap { jetton in
        do {
          let quantity = BigUInt(stringLiteral: jetton.balance)
          let walletAddress = try Address.parse(jetton.wallet_address.address)
          let jettonInfo = try JettonInfo(jettonPreview: jetton.jetton)
          let jettonItem = JettonItem(jettonInfo: jettonInfo, walletAddress: walletAddress)
          let jettonBalance = JettonBalance(item: jettonItem, quantity: quantity)
          return jettonBalance
        } catch {
          return nil
        }
      }
  }
}

//// MARK: - Events

extension API {
  func getAccountEvents(address: Address,
                        beforeLt: Int64?,
                        limit: Int) async throws -> AccountEvents {
    let response = try await tonAPIClient.getAccountEvents(
      path: .init(account_id: address.toRaw()),
      query: .init(before_lt: beforeLt,
                   limit: limit,
                   start_date: nil,
                   end_date: nil)
    )
    let entity = try response.ok.body.json
    let events: [AccountEvent] = entity.events.compactMap {
      guard let activityEvent = try? AccountEvent(accountEvent: $0) else { return nil }
      return activityEvent
    }
    return AccountEvents(address: address,
                          events: events,
                          startFrom: beforeLt ?? 0,
                          nextFrom: entity.next_from)
  }
  
  func getAccountJettonEvents(address: Address,
                              jettonInfo: JettonInfo,
                              beforeLt: Int64?,
                              limit: Int) async throws -> AccountEvents {
    let response = try await tonAPIClient.getAccountJettonHistoryByID(
      path: .init(account_id: address.toRaw(),
                  jetton_id: jettonInfo.address.toRaw()),
      query: .init(before_lt: beforeLt,
                   limit: limit,
                   start_date: nil,
                   end_date: nil)
    )
    let entity = try response.ok.body.json
    let events: [AccountEvent] = entity.events.compactMap {
      guard let activityEvent = try? AccountEvent(accountEvent: $0) else { return nil }
      return activityEvent
    }
    return AccountEvents(address: address,
                          events: events,
                          startFrom: beforeLt ?? 0,
                          nextFrom: entity.next_from)
  }
  
  func getEvent(address: Address,
                eventId: String) async throws -> AccountEvent {
    let response = try await tonAPIClient
      .getAccountEvent(path: .init(account_id: address.toRaw(),
                                   event_id: eventId))
    return try AccountEvent(accountEvent: try response.ok.body.json)
  }
}

// MARK: - Wallet

extension API {
  func getSeqno(address: Address) async throws -> Int {
    let response = try await tonAPIClient
      .getAccountSeqno(path: .init(account_id: address.toRaw()))
    return try response.ok.body.json.seqno
  }
  
  func emulateMessageWallet(boc: String) async throws -> Components.Schemas.MessageConsequences {
    let response = try await tonAPIClient
      .emulateMessageToWallet(body: .json(.init(boc: boc)))
    return try response.ok.body.json
  }
  
  func sendTransaction(boc: String) async throws {
    let response = try await tonAPIClient
      .sendBlockchainMessage(body: .json(.init(boc: boc)))
    _ = try response.ok
  }
}

// MARK: - NFTs

extension API {
  func getAccountNftItems(address: Address,
                          collectionAddress: Address?,
                          limit: Int,
                          offset: Int,
                          isIndirectOwnership: Bool) async throws -> [NFT] {
    let response = try await tonAPIClient.getAccountNftItems(
      path: .init(account_id: address.toRaw()),
      query: .init(collection: collectionAddress?.toRaw(),
                   limit: limit,
                   offset: offset,
                   indirect_ownership: isIndirectOwnership)
    )
    let entity = try response.ok.body.json
    let collectibles = entity.nft_items.compactMap {
      try? NFT(nftItem: $0)
    }
    
    return collectibles
  }
  
  func getNftItemsByAddresses(_ addresses: [Address]) async throws -> [NFT] {
    let response = try await tonAPIClient
      .getNftItemsByAddresses(
        .init(
          body: .json(.init(account_ids: addresses.map { $0.toRaw() })))
      )
    let entity = try response.ok.body.json
    let nfts = entity.nft_items.compactMap {
      try? NFT(nftItem: $0)
    }
    return nfts
  }
}

// MARK: - Rates

extension API {
  func getRates(jettons: [JettonInfo],
                currencies: [Currency]) async throws -> Rates {
    let requestTokens = ([TonInfo.symbol.lowercased()] + jettons.map { $0.address.toRaw() })
      .joined(separator: ",")
    let requestCurrencies = currencies.map { $0.code }
      .joined(separator: ",")
    let response = try await tonAPIClient
      .getRates(query: .init(tokens: requestTokens, currencies: requestCurrencies))
    let entity = try response.ok.body.json
    return parseResponse(rates: entity.rates.additionalProperties, jettons: jettons)
  }
  
  private func parseResponse(rates: [String: Components.Schemas.TokenRates],
                             jettons: [JettonInfo]) -> Rates {
    var tonRates = [Rates.Rate]()
    var jettonsRates = [Rates.JettonRate]()
    for key in rates.keys {
      guard let jettonRates = rates[key] else { continue }
      if key.lowercased() == TonInfo.symbol.lowercased() {
        guard let prices = jettonRates.prices?.additionalProperties else { continue }
        let diff24h = jettonRates.diff_24h?.additionalProperties
        tonRates = prices.compactMap { price -> Rates.Rate? in
          guard let currency = Currency(code: price.key) else { return nil }
          let diff24h = diff24h?[price.key]
          return Rates.Rate(currency: currency, rate: Decimal(price.value), diff24h: diff24h)
        }
        continue
      }
      guard let jettonInfo = jettons.first(where: { $0.address.toRaw() == key.lowercased()}) else { continue }
      guard let prices = jettonRates.prices?.additionalProperties else { continue }
      let diff24h = jettonRates.diff_24h?.additionalProperties
      let rates: [Rates.Rate] = prices.compactMap { price -> Rates.Rate? in
        guard let currency = Currency(code: price.key) else { return nil }
        let diff24h = diff24h?[price.key]
        return Rates.Rate(currency: currency, rate: Decimal(price.value), diff24h: diff24h)
      }
      jettonsRates.append(.init(jettonInfo: jettonInfo, rates: rates))
      
    }
    return Rates(ton: tonRates, jettonsRates: jettonsRates)
  }
}

// MARK: - DNS

extension API {
  enum DNSError: Swift.Error {
    case noWalletData
  }
  
  func resolveDomainName(_ domainName: String) async throws -> FriendlyAddress {
    let response = try await tonAPIClient.dnsResolve(path: .init(domain_name: domainName))
    let entity = try response.ok.body.json
    guard let wallet = entity.wallet else {
      throw DNSError.noWalletData
    }
    
    let address = try Address.parse(wallet.address)
    return FriendlyAddress(address: address, bounceable: !wallet.is_wallet)
  }
  
  func getDomainExpirationDate(_ domainName: String) async throws -> Date? {
    let response = try await tonAPIClient.getDnsInfo(path: .init(domain_name: domainName))
    let entity = try response.ok.body.json
    guard let expiringAt = entity.expiring_at else { return nil }
    return Date(timeIntervalSince1970: TimeInterval(integerLiteral: Int64(expiringAt)))
  }
}

//// MARK: - Time
//
//extension API {
//  func getTime() async throws -> TimeInterval {
//    let response = try await tonAPIClient.getRawTime(Operations.getRawTime.Input())
//    let entity = try response.ok.body.json
//    return TimeInterval(entity.time)
//  }
//}
