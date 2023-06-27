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
    typealias StoreKey = TonSwift.PublicKey
    
    private let keychainManager: KeychainManager
    private let walletID: WalletID
    
    init(keychainManager: KeychainManager,
         walletID: WalletID) {
        self.keychainManager = keychainManager
        self.walletID = walletID
    }
    
    func loadValue(key: TonSwift.PublicKey) throws -> [String] {
        let query = KeychainQuery(class: .genericPassword(service: walletID.string,
                                                          account: key.hexString),
                                  accessible: .whenUnlockedThisDeviceOnly)
        let data = try keychainManager.get(query: query)
        let decoder = JSONDecoder()
        return try decoder.decode([String].self, from: data)
    }
    
    func save(value: [String], for key: TonSwift.PublicKey) throws {
        let query = KeychainQuery(class: .genericPassword(service: walletID.string,
                                                          account: key.hexString),
                                  accessible: .whenUnlockedThisDeviceOnly)
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        try keychainManager.save(data: data, query: query)
    }
}
