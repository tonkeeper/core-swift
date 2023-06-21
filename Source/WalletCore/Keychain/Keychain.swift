//
//  Keychain.swift
//  
//
//  Created by Grigory on 21.6.23..
//

import Foundation

enum KeychainResult {
    case success
    case failed
}

enum KeychainGetResult<AnyObject> {
    case success(object: AnyObject)
    case failed
}

protocol Keychain {
    typealias Query = [String: AnyObject]
    typealias Attributes = [String: AnyObject]
    func save(query: Query) -> KeychainResult
    func get(query: Query) -> KeychainGetResult<AnyObject>
    func update(query: Query, attributes: Attributes) -> KeychainResult
    func delete(query: Query) -> KeychainResult
}

final class KeychainImplementation: Keychain {
    func save(query: Query) -> KeychainResult {
        let resultCode = SecItemAdd(query as CFDictionary, nil)
        return resultCode == noErr ? .success : .failed
    }
    
    func get(query: Query) -> KeychainGetResult<AnyObject> {
        var resultValue: AnyObject?
        let resultCode = withUnsafeMutablePointer(to: &resultValue) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        guard resultCode == noErr, let resultValue = resultValue else {
            return .failed
        }
        
        return .success(object: resultValue)
    }
    
    func update(query: Query, attributes: Attributes) -> KeychainResult {
        let resultCode = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        return resultCode == noErr ? .success : .failed
    }
    
    func delete(query: Query) -> KeychainResult {
        let resultCode = SecItemDelete(query as CFDictionary)
        return resultCode == noErr ? .success : .failed
    }
}
