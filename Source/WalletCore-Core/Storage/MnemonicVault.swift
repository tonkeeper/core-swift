//
//  MnemonicVault.swift
//
//
//  Created by Grigory Serebryanyy on 20.11.2023.
//

import Foundation

struct MnemonicVault: StorableKeyValueVault {
    typealias StoreValue = Mnemonic
    typealias StoreKey = Wallet
    
    private let keychainVault: KeychainVault
    private let accessGroup: String?
    
    init(keychainVault: KeychainVault,
         accessGroup: String?) {
        self.keychainVault = keychainVault
        self.accessGroup = accessGroup
    }
    
    func saveValue(_ value: Mnemonic, for key: Wallet) throws {
        try keychainVault.saveValue(value, to: key.queryable(accessGroup: accessGroup))
    }
    
    func deleteValue(for key: Wallet) throws {
        try keychainVault.deleteItem(key.queryable(accessGroup: accessGroup))
    }
    
    func loadValue(key: Wallet) throws -> Mnemonic {
        try keychainVault.readValue(key.queryable(accessGroup: accessGroup))
    }
}

private extension Wallet {
    func queryable(accessGroup: String?) throws -> KeychainQueryable {
        KeychainGenericPasswordItem(service: try identity.id().string,
                                    account: try publicKey.hexString,
                                    accessGroup: accessGroup,
                                    accessible: .whenUnlockedThisDeviceOnly)
    }
}
