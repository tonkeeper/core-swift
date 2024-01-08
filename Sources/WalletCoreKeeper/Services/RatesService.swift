//
//  RatesService.swift
//
//
//  Created by Grigory on 2.7.23..
//

import Foundation
import TonSwift
import TonAPI
import WalletCoreCore

protocol RatesService {
    func loadRates(tonInfo: TonInfo, tokens: [TokenInfo], currencies: [Currency]) async throws -> Rates
    func getRates() -> Rates
}

actor RatesServiceImplementation: RatesService {
    
    private let api: API
    private let localRepository: any LocalRepository<Rates>
    
    init(api: API,
         localRepository: any LocalRepository<Rates>) {
        self.api = api
        self.localRepository = localRepository
    }
    
    nonisolated func getRates() -> Rates {
        do {
            return try localRepository.load(fileName: Rates.fileName)
        } catch {
            return Rates(ton: [], tokens: [])
        }
    }
    
    func loadRates(tonInfo: TonInfo, tokens: [TokenInfo], currencies: [Currency]) async throws -> Rates {
        let rates = try await api.getRates(
            tonInfo: tonInfo,
            tokens: tokens,
            currencies: currencies)
        updateCache(with: rates)
        return rates
    }
}

private extension RatesServiceImplementation {
    func updateCache(with rates: Rates) {
        var cachedRates = getRates()
        cachedRates.ton = rates.ton
        
        for tokenRate in rates.tokens {
            if let cachedTokenRatesIndex = cachedRates.tokens.firstIndex(where: { $0.tokenInfo == tokenRate.tokenInfo }) {
                cachedRates.tokens[cachedTokenRatesIndex].rates = tokenRate.rates
            } else {
                cachedRates.tokens.append(tokenRate)
            }
        }
        do {
            try localRepository.save(item: cachedRates)
        } catch {}
    }
}
