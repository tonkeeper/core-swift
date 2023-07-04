//
//  RatesService.swift
//
//
//  Created by Grigory on 2.7.23..
//

import Foundation
import TonSwift
import TonAPI

protocol RatesService {
    func loadRates(tonInfo: TonInfo, tokens: [TokenInfo], currencies: [Currency]) async throws -> Rates
    func getRates() throws -> Rates
}

final class RatesServiceImplementation: RatesService {
    
    private let api: API
    private let localRepository: any LocalRepository<Rates>
    
    init(api: API,
         localRepository: any LocalRepository<Rates>) {
        self.api = api
        self.localRepository = localRepository
    }
    
    func getRates() throws -> Rates {
        return try localRepository.load(fileName: Rates.fileName)
    }
    
    func loadRates(tonInfo: TonInfo, tokens: [TokenInfo], currencies: [Currency]) async throws -> Rates {
        let requestTokens: [String] = tokens.map { $0.address.toString() }
        let requestCurrencies = currencies.map { $0.code }
        
        let tokensRates: [Rates.TokenRate] = try await withThrowingTaskGroup(of: [Rates.TokenRate].self) { [weak self] group in
            guard let self = self else { throw NSError(domain: "", code: 1) }
            for token in requestTokens {
                group.addTask {
                    let request = RatesRequest(tokens: [token], currencies: requestCurrencies)
                    let response = try? await self.api.send(request: request)
                    
                    guard let responseRates = response?.entity.tokensRates else { return [] }
                    
                    var tokensRates = [Rates.TokenRate]()
                    for responseRate in responseRates {
                        guard let tokenInfo = tokens.first(where: { $0.address.toString() == responseRate.key }) else { continue }
                        guard !responseRate.rates.isEmpty else { continue }
                        let rates: [Rates.Rate] = responseRate.rates.compactMap {
                            guard let currrency = Currency(rawValue: $0.code) else { return nil }
                            return Rates.Rate(currency: currrency, rate: $0.rate)
                        }
                        tokensRates.append(.init(tokenInfo: tokenInfo, rates: rates))
                    }
                    return tokensRates
                }
            }
            
            var tokensRates = [Rates.TokenRate]()
            for try await rate in group {
                tokensRates.append(contentsOf: rate)
            }
            
            return tokensRates
        }
        
        let request = RatesRequest(tokens: ["ton"], currencies: requestCurrencies)
        let response = try await self.api.send(request: request)
        
        var tonRates = [Rates.Rate]()
        for tokenRate in response.entity.tokensRates {
            if tokenRate.key.lowercased() == tonInfo.symbol.lowercased() {
                tonRates = tokenRate.rates.compactMap {
                    guard let currrency = Currency(rawValue: $0.code) else { return nil }
                    return Rates.Rate(currency: currrency, rate: $0.rate)
                }
                continue
            }

        }
        
        let rates = Rates(ton: tonRates, tokens: tokensRates)
        try? localRepository.save(item: rates)
        return rates
    }
}
