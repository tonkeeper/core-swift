import Foundation
import TonSwift

public final class MainController {
  
  public var didUpdateNftsAvailability: ((Bool) -> Void)?
  public var didReceiveTonConnectRequest: ((TonConnect.AppRequest, Wallet, TonConnectApp) -> Void)?
  
  private let walletsStore: WalletsStore
  private let nftsStoreProvider: (Wallet) -> NftsStore
  private let backgroundUpdateStore: BackgroundUpdateStore
  private let tonConnectEventsStore: TonConnectEventsStore
  private let knownAccountsStore: KnownAccountsStore
  private let balanceStore: BalanceStore
  private let dnsService: DNSService
  private let tonConnectService: TonConnectService
  private let deeplinkParser: DeeplinkParser
  // TODO: wrap to service
  private let api: API
  
  private var nftsStore: NftsStore?
  private var nftStateTask: Task<Void, Never>?

  init(walletsStore: WalletsStore, 
       nftsStoreProvider: @escaping (Wallet) -> NftsStore,
       backgroundUpdateStore: BackgroundUpdateStore,
       tonConnectEventsStore: TonConnectEventsStore,
       knownAccountsStore: KnownAccountsStore,
       balanceStore: BalanceStore,
       dnsService: DNSService,
       tonConnectService: TonConnectService,
       deeplinkParser: DeeplinkParser,
       api: API) {
    self.walletsStore = walletsStore
    self.nftsStoreProvider = nftsStoreProvider
    self.backgroundUpdateStore = backgroundUpdateStore
    self.tonConnectEventsStore = tonConnectEventsStore
    self.knownAccountsStore = knownAccountsStore
    self.balanceStore = balanceStore
    self.dnsService = dnsService
    self.tonConnectService = tonConnectService
    self.deeplinkParser = deeplinkParser
    self.api = api
    
    walletsStore.addObserver(self)
    Task {
      await backgroundUpdateStore.addObserver(self)
    }
    Task {
      await tonConnectEventsStore.addObserver(self)
    }
  }
  
  public func loadNftsState() {
    nftStateTask?.cancel()
    nftStateTask = nil
    
    nftsStore = nftsStoreProvider(walletsStore.activeWallet)
    Task {
      await nftsStore?.addObserver(self)
      let cachedNfts = (await self.nftsStore?.getNfts()) ?? []
      didUpdateNftsAvailability?(!cachedNfts.isEmpty)
      nftStateTask = Task {
        await nftsStore?.loadInitialNfts()
      }
    }
  }
  
  public func startBackgroundUpdate() {
    Task {
      await backgroundUpdateStore.start(addresses: walletsStore.wallets.compactMap { try? $0.address })
    }
    Task {
      await tonConnectEventsStore.start()
    }
  }
  
  public func stopBackgroundUpdate() {
    Task {
      await backgroundUpdateStore.stop()
    }
    Task {
      await tonConnectEventsStore.stop()
    }
  }
  
  public func handleTonConnectDeeplink(_ deeplink: TonConnectDeeplink) async throws -> (TonConnectParameters, TonConnectManifest) {
    try await tonConnectService.loadTonConnectConfiguration(with: deeplink)
  }
  
  public func parseDeeplink(deeplink: String?) throws -> Deeplink {
    try deeplinkParser.parse(string: deeplink)
  }
  
  public func resolveRecipient(_ recipient: String) async -> Recipient? {
    let inputRecipient: Recipient?
    let knownAccounts = (try? await knownAccountsStore.getKnownAccounts()) ?? []
    if let friendlyAddress = try? FriendlyAddress(string: recipient) {
      inputRecipient = Recipient(
        recipientAddress: .friendly(
          friendlyAddress
        ),
        isMemoRequired: knownAccounts.first(where: { $0.address == friendlyAddress.address })?.requireMemo ?? false
      )
    } else if let rawAddress = try? Address.parse(recipient) {
      inputRecipient = Recipient(
        recipientAddress: .raw(
          rawAddress
        ),
        isMemoRequired: knownAccounts.first(where: { $0.address == rawAddress })?.requireMemo ?? false
      )
    } else if let domain = try? await dnsService.resolveDomainName(recipient) {
      inputRecipient = Recipient(
        recipientAddress: .domain(domain),
        isMemoRequired: knownAccounts.first(where: { $0.address == domain.friendlyAddress.address })?.requireMemo ?? false
      )
    } else {
      inputRecipient = nil
    }
    return inputRecipient
  }
  
  public func resolveJetton(jettonAddress: Address) async -> JettonItem? {
    do {
      let jettonInfo = try await api.resolveJetton(address: jettonAddress)
      for wallet in walletsStore.wallets {
        guard let balance = try? balanceStore.getBalance(wallet: walletsStore.activeWallet).balance else {
          continue
        }
        guard let jettonItem =  balance.jettonsBalance.first(where: { $0.item.jettonInfo == jettonInfo })?.item else {
          continue
        }
        return jettonItem
      }
      return nil
    } catch {
      return nil
    }
  }
}

extension MainController: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    switch event {
    case .didUpdateActiveWallet:
      didUpdateNftsAvailability?(false)
      loadNftsState()
    case .didAddWallets:
      startBackgroundUpdate()
    default:
      break
    }
  }
}

extension MainController: NftsStoreObserver {
  func didGetNftsStoreEvent(_ event: NftsStore.Event) {
    switch event {
    case .didUpdateNFTs(let nfts):
      didUpdateNftsAvailability?(!nfts.isEmpty)
    }
  }
}

extension MainController: BackgroundUpdateStoreObserver {
  public func didGetBackgroundUpdateStoreEvent(_ event: BackgroundUpdateStore.Event) {
    switch event {
    case .didReceiveUpdateEvent(let event):
      do {
        guard try event.accountAddress == walletsStore.activeWallet.address else { return }
        loadNftsState()
      } catch {}
    case .didUpdateState(let state):
      switch state {
      case .connected:
        loadNftsState()
      default:
        break
      }
    }
  }
}

extension MainController: TonConnectEventsStoreObserver {
  public func didGetTonConnectEventsStoreEvent(_ event: TonConnectEventsStore.Event) {
    switch event {
    case .request(let request, let wallet, let app):
      Task { @MainActor in
        didReceiveTonConnectRequest?(request, wallet, app)
      }
    }
  }
}
