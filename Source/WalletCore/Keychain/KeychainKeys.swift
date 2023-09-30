//
//  KeychainKeys.swift
//  
//
//  Created by Grigory on 22.6.23..
//

import Foundation

struct KeychainKeys {
    static var attrAccount: String {
        kSecAttrAccount.string
    }
    
    static var attrAccessible: String {
        kSecAttrAccessible.string
    }
    
    static var attrAccessGroup: String {
        kSecAttrAccessGroup.string
    }
    
    static var valueData: String {
        kSecValueData.string
    }
    
    static var `class`: String {
        kSecClass.string
    }
    
    static var attrService: String {
        kSecAttrService.string
    }
    
    static var returnData: String {
        kSecReturnData.string
    }
}

private extension CFString {
    var string: String {
        self as String
    }
}
