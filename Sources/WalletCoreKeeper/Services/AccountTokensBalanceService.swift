//
//  AccountTokensBalanceService.swift
//  
//
//  Created by Grigory on 1.7.23..
//

import Foundation
import TonSwift
import TonAPI
import BigInt

protocol AccountTokensBalanceService {
    func loadTokensBalance(address: Address) async throws -> [TokenBalance]
}

final class AccountTokensBalanceServiceImplementation: AccountTokensBalanceService {
    
    private let api: API
    
    init(api: API) {
        self.api = api
    }
    
    func loadTokensBalance(address: Address) async throws -> [TokenBalance] {
        let tokensBalance = try await api.getAccountJettonsBalances(address: address)
        return tokensBalance.filter { !$0.amount.quantity.isZero }
    }
}
