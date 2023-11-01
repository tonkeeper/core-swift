//
//  TonConnectAppsVault.swift
//  
//
//  Created by Grigory Serebryanyy on 26.10.2023.
//

import Foundation
import TonSwift

struct TonConnectAppsVault: StorableVault {
    enum Error: Swift.Error {
        case noConnectedApps
        case connectedAppsDataCorrupted
    }
    
    typealias StoreValue = TonConnectApps
    typealias StoreKey = Wallet
    
    private let keychainManager: KeychainManager
    private let keychainGroup: String
    
    init(keychainManager: KeychainManager,
         keychainGroup: String) {
        self.keychainManager = keychainManager
        self.keychainGroup = keychainGroup
    }
    
    func save(value: TonConnectApps, for key: Wallet) throws {
        let query = KeychainQuery(
            class: .genericPassword(service: try key.identity.id().string,
                                    account: .key),
            accessible: .whenUnlockedThisDeviceOnly,
            accessGroup: keychainGroup
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        try keychainManager.save(data: data, query: query)
    }
    
    func loadValue(key: Wallet) throws -> TonConnectApps {
        do {
            let query = KeychainQuery(class: .genericPassword(service: try key.identity.id().string,
                                                              account: .key),
                                      accessible: .whenUnlockedThisDeviceOnly,
                                      accessGroup: keychainGroup)
            let data = try keychainManager.get(query: query)
            let decoder = JSONDecoder()
            return try decoder.decode(TonConnectApps.self, from: data)
        } catch is KeychainManager.Error {
            throw Error.noConnectedApps
        } catch is DecodingError {
            throw Error.connectedAppsDataCorrupted
        }
    }
}

private extension String {
    static let key: String = "TonConnectApps"
}
