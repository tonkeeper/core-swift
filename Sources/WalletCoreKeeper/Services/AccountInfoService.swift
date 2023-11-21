//
//  AccountInfoService.swift
//  
//
//  Created by Grigory on 1.8.23..
//

import Foundation
import TonSwift
import TonAPI

protocol AccountInfoService {
    func loadAccountInfo(address: Address) async throws -> Account
}

final class AccountInfoServiceImplementation: AccountInfoService {
    
    private let api: API
    
    init(api: API) {
        self.api = api
    }
    
    func loadAccountInfo(address: Address) async throws -> Account {
        try await api.getAccountInfo(address: address)
    }
}

