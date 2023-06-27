//
//  KeychainKeysVault.swift
//  
//
//  Created by Grigory on 27.6.23..
//

import Foundation
import TonSwift

struct KeychainKeysVault: StorableVault {
    typealias StoreValue = TonSwift.PrivateKey
    typealias StoreKey = TonSwift.PublicKey
    
    private let keychainManager: KeychainManager
    private let walletID: WalletID
    
    init(keychainManager: KeychainManager,
         walletID: WalletID) {
        self.keychainManager = keychainManager
        self.walletID = walletID
    }
    
    func loadValue(key: TonSwift.PublicKey) throws -> TonSwift.PrivateKey {
        let query = KeychainQuery(class: .genericPassword(service: walletID.string,
                                                          account: key.hexString),
                                  accessible: .whenUnlockedThisDeviceOnly)
        let privateKeyData = try keychainManager.get(query: query)
        return .init(data: privateKeyData)
    }
    
    func save(value: TonSwift.PrivateKey, for key: TonSwift.PublicKey) throws {
        let query = KeychainQuery(class: .genericPassword(service: walletID.string,
                                                          account: key.hexString),
                                  accessible: .whenUnlockedThisDeviceOnly)
        try keychainManager.save(data: value.data, query: query)
    }
}
