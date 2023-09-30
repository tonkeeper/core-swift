//
//  Keychain.swift
//  
//
//  Created by Grigory on 21.6.23..
//

import Foundation

enum KeychainResultCode: Equatable {
    case success                      // 0
    case errSecParam                  // -50
    case errSecAllocate               // -108
    case errSecNotAvailable           // -25291
    case errSecAuthFailed             // -25293
    case errSecDuplicateItem          // -25299
    case errSecItemNotFound           // -25300
    case errSecDecode                 // -26275
    case other(OSStatus)
    
    init(status: OSStatus) {
        switch status {
        case 0: self = .success
        case -50: self = .errSecParam
        case -108: self = .errSecAllocate
        case -25291: self = .errSecNotAvailable
        case -25293: self = .errSecAuthFailed
        case -25299: self = .errSecDuplicateItem
        case -25300: self = .errSecItemNotFound
        case -26275: self = .errSecDecode
        default:
            self = .other(status)
        }
    }
}

struct KeychainQuery {
    enum Accessible {
        case whenUnlocked
        case afterFirstUnlock
        case whenPasscodeSetThisDeviceOnly
        case whenUnlockedThisDeviceOnly
        case afterFirstUnlockThisDeviceOnly
        
        var keychainKey: CFString {
            switch self {
            case .afterFirstUnlock:
                return kSecAttrAccessibleAfterFirstUnlock
            case .afterFirstUnlockThisDeviceOnly:
                return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            case .whenPasscodeSetThisDeviceOnly:
                return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            case .whenUnlocked:
                return kSecAttrAccessibleWhenUnlocked
            case .whenUnlockedThisDeviceOnly:
                return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            }
        }
    }
    
    enum Class {
        case genericPassword(service: String, account: String?)
        
        var queryItems: [String: AnyObject] {
            switch self {
            case let .genericPassword(service, account):
                var result = [KeychainKeys.class: kSecClassGenericPassword,
                              KeychainKeys.attrService: service as AnyObject]
                if let account = account {
                    result[KeychainKeys.attrAccount] = account as AnyObject
                }
                return result
            }
        }
    }
    
    var accessible: Accessible
    var accessGroup: String?
    var `class`: Class
    var returnData: Bool
    var data: Data?
    
    init(class: Class, accessible: Accessible, accessGroup: String? = nil, returnData: Bool = true) {
        self.class = `class`
        self.accessible = accessible
        self.accessGroup = accessGroup
        self.returnData = returnData
    }
    
    var query: [String: AnyObject] {
        var result = [String: AnyObject]()
        result[KeychainKeys.attrAccessible] = accessible.keychainKey as AnyObject
        result.merge(`class`.queryItems, uniquingKeysWith: { (_, new) in new })
        if let accessGroup = accessGroup {
            result[KeychainKeys.attrAccessGroup] = accessGroup as AnyObject
        }
        if returnData {
            result[KeychainKeys.returnData] = true as AnyObject
        }
        if let data = data {
            result[KeychainKeys.valueData] = data as AnyObject
        }
        return result
    }
}

enum KeychainGetResult<T> {
    case success(T)
    case failed(KeychainResultCode)
}

protocol Keychain {
    typealias Attributes = [String: AnyObject]
    func save(query: KeychainQuery) -> KeychainResultCode
    func get(query: KeychainQuery) -> KeychainGetResult<Data?>
    func update(query: KeychainQuery, attributes: Attributes) -> KeychainResultCode
    func delete(query: KeychainQuery) -> KeychainResultCode
}

protocol KeychainQueryable {
    var query: KeychainQuery { get }
}

final class KeychainImplementation: Keychain {
    func save(query: KeychainQuery) -> KeychainResultCode {
        let resultCode = SecItemAdd(query.query as CFDictionary, nil)
        return KeychainResultCode(status: resultCode)
    }

    func get(query: KeychainQuery) -> KeychainGetResult<Data?> {
        var resultValue: AnyObject?
        let resultCode = withUnsafeMutablePointer(to: &resultValue) {
            SecItemCopyMatching(query.query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        let result = KeychainResultCode(status: resultCode)
        switch result {
        case .success:
            return .success(resultValue as? Data)
        default:
            return .failed(result)
        }
    }

    func update(query: KeychainQuery, attributes: Keychain.Attributes) -> KeychainResultCode {
        let resultCode = SecItemUpdate(query.query as CFDictionary, attributes as CFDictionary)
        return KeychainResultCode(status: resultCode)
    }

    func delete(query: KeychainQuery) -> KeychainResultCode {
        let resultCode = SecItemDelete(query.query as CFDictionary)
        return KeychainResultCode(status: resultCode)
    }
}
