//
//  KeychainVault.swift
//  
//
//  Created by Grigory on 22.6.23..
//

import Foundation
import TonSwift

struct KeychainVault: Vault, StorableVault {
    private let keychainManager: KeychainManager
    private let walletID: WalletID
    
    init(keychainManager: KeychainManager,
         walletID: WalletID) {
        self.keychainManager = keychainManager
        self.walletID = walletID
    }
    
    func loadKey(publicKey: TonSwift.PublicKey) throws -> TonSwift.PrivateKey {
        let query = KeychainQuery(class: .genericPassword(service: walletID.string,
                                                          account: publicKey.hexString),
                                  accessible: .whenUnlockedThisDeviceOnly)
        let privateKeyData = try keychainManager.get(query: query)
        return .init(data: privateKeyData)
    }
    
    func saveKeyPair(_ keyPair: TonSwift.KeyPair) throws {
        let query = KeychainQuery(class: .genericPassword(service: walletID.string,
                                                          account: keyPair.publicKey.hexString),
                                  accessible: .whenUnlockedThisDeviceOnly)
        try keychainManager.save(data: keyPair.privateKey.data, query: query)
    }
}
