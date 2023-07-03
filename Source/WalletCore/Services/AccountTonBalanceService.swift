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
        let request = AccountRequest(accountId: address.toRaw())
        let response = try await api.send(request: request)

        let tonAmount = TonAmount(quantity: response.entity.balance)
        let tonBalance = TonBalance(walletAddress: try .parse(response.entity.address),
                                    amount: tonAmount)
        return tonBalance
    }
}
