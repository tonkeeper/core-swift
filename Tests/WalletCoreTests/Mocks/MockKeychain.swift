//
//  MockKeychain.swift
//  
//
//  Created by Grigory on 22.6.23..
//

import Foundation
@testable import WalletCore

final class MockKeychain: Keychain {
    
    var resultCode: KeychainResultCode = .other(-1)
    var getResult: KeychainGetResult<Data?> = .failed(.other(-1))
    var data: Data?
    var query: KeychainQuery = .init(class: .genericPassword(service: "", account: ""), accessible: .whenUnlocked)
    var updateAttributes: Attributes = [:]
    
    func save(query: KeychainQuery) -> KeychainResultCode {
        self.query = query
        return resultCode
    }
    
    func get(query: KeychainQuery) -> KeychainGetResult<Data?> {
        self.query = query
        return getResult
    }
    
    func update(query: KeychainQuery, attributes: Attributes) -> KeychainResultCode {
        self.query = query
        self.updateAttributes = attributes
        return resultCode
    }
    
    func delete(query: KeychainQuery) -> KeychainResultCode {
        self.query = query
        return resultCode
    }
    
    func reset() {
        data = nil
        resultCode = .other(-1)
        updateAttributes = [:]
    }
}
