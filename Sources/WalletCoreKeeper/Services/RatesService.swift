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
    func getRates() throws -> Rates
}

actor RatesServiceImplementation: RatesService {
    
    private let api: API
    private let localRepository: any LocalRepository<Rates>
    
    init(api: API,
         localRepository: any LocalRepository<Rates>) {
        self.api = api
        self.localRepository = localRepository
    }
    
    nonisolated func getRates() throws -> Rates {
        return try localRepository.load(fileName: Rates.fileName)
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
        guard var cachedRates = try? getRates() else {
            try? localRepository.save(item: rates)
            return
        }
        
        cachedRates.ton = rates.ton
        
        for tokenRate in rates.tokens {
            guard let cachedTokenRatesIndex = cachedRates.tokens.firstIndex(where: { $0.tokenInfo == tokenRate.tokenInfo }) else {
                continue
            }
            
            cachedRates.tokens[cachedTokenRatesIndex].rates = tokenRate.rates
        }
        
        try? localRepository.save(item: cachedRates)
    }
}
