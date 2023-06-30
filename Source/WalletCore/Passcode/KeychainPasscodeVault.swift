//
//  KeychainPasscodeVault.swift
//  
//
//  Created by Grigory on 30.6.23..
//

import Foundation
import TonSwift

struct KeychainPasscodeVault {
    private let keychainManager: KeychainManager
    
    init(keychainManager: KeychainManager) {
        self.keychainManager = keychainManager
    }
    
    func load() throws -> Passcode {
        let query = KeychainQuery(
            class: .genericPassword(service: .service,
                                    account: .account),
            accessible: .whenUnlockedThisDeviceOnly
        )
        let data = try keychainManager.get(query: query)
        let decoder = JSONDecoder()
        return try decoder.decode(Passcode.self, from: data)
    }
    
    func save(_ passcode: Passcode) throws {
        let query = KeychainQuery(
            class: .genericPassword(service: .service,
                                    account: .account),
            accessible: .whenUnlockedThisDeviceOnly
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(passcode)
        try keychainManager.save(data: data, query: query)
    }
}

private extension String {
    static let service = "PasscodeVault"
    static let account = "Passcode"
}

