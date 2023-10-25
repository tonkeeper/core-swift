//
//  AccountTonBalanceService.swift
//  
//
//  Created by Grigory on 1.7.23..
//

import Foundation
import TonSwift
import TonAPI

protocol AccountTonBalanceService {
    func loadBalance(address: Address) async throws -> TonBalance
}

final class AccountTonBalanceServiceImplementation: AccountTonBalanceService {
    
    private let api: API
    
    init(api: API) {
        self.api = api
    }
    
    func loadBalance(address: Address) async throws -> TonBalance {
        let account = try await api.getAccountInfo(address: address)
        let tonAmount = TonAmount(quantity: account.balance)
        let tonBalance = TonBalance(walletAddress: account.address,
                                    amount: tonAmount)
        return tonBalance
    }
}
