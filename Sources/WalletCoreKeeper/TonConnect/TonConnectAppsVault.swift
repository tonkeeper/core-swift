//
//  TonConnectAppsVault.swift
//  
//
//  Created by Grigory Serebryanyy on 26.10.2023.
//

import Foundation
import TonSwift
import WalletCoreCore

struct TonConnectAppsVault: StorableKeyValueVault {
    typealias StoreValue = TonConnectApps
    typealias StoreKey = Wallet
    
    private let keychainVault: KeychainVault
    private let accessGroup: String?
    
    init(keychainVault: KeychainVault,
         accessGroup: String?) {
        self.keychainVault = keychainVault
        self.accessGroup = accessGroup
    }
    
    func saveValue(_ value: TonConnectApps, for key: WalletCoreCore.Wallet) throws {
        try keychainVault.saveValue(value, to: key.query(accessGroup: accessGroup))
    }
    
    func deleteValue(for key: WalletCoreCore.Wallet) throws {
        try keychainVault.deleteItem(key.query(accessGroup: accessGroup))
    }
    
    func loadValue(key: WalletCoreCore.Wallet) throws -> TonConnectApps {
        try keychainVault.readValue(key.query(accessGroup: accessGroup))
    }
}

private extension Wallet {
    func query(accessGroup: String?) throws -> WalletCoreCore.KeychainQueryable {
        KeychainGenericPasswordItem(service: try identity.id().string,
                                    account: .key,
                                    accessGroup: accessGroup,
                                    accessible: .whenUnlockedThisDeviceOnly)
    }
}

private extension String {
    static let key: String = "TonConnectApps"
}
