//
//  KeychainVault.swift
//  
//
//  Created by Grigory on 22.6.23..
//

import Foundation
import TonSwift

struct KeychainMnemonicVault: StorableVault {
    typealias StoreValue = [String]
    typealias StoreKey = Wallet
    
    private let keychainManager: KeychainManager
    private let keychainGroup: String
    
    init(keychainManager: KeychainManager,
         keychainGroup: String) {
        self.keychainManager = keychainManager
        self.keychainGroup = keychainGroup
    }
    
    func loadValue(key: Wallet) throws -> [String] {
        let query = KeychainQuery(
            class: .genericPassword(service: try key.identity.id().string,
                                    account: try key.publicKey.hexString),
            accessible: .whenUnlockedThisDeviceOnly,
            accessGroup: keychainGroup
        )
        let data = try keychainManager.get(query: query)
        let decoder = JSONDecoder()
        return try decoder.decode([String].self, from: data)
    }
    
    func save(value: [String], for key: Wallet) throws {
        let query = KeychainQuery(class: .genericPassword(service: try key.identity.id().string,
                                                          account: try key.publicKey.hexString),
                                  accessible: .whenUnlockedThisDeviceOnly,
                                  accessGroup: keychainGroup)
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        try keychainManager.save(data: data, query: query)
    }
}
