//
//  File.swift
//  
//
//  Created by Grigory Serebryanyy on 20.11.2023.
//

import Foundation

struct KeychainGenericPasswordItem: KeychainQueryable {
    let service: String
    let account: String?
    let accessGroup: String?
    let accessible: KeychainAccessible
    
    var query: [String : AnyObject] {
        var query = [String: AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject
        if let account = account {
            query[kSecAttrAccount as String] = account as AnyObject
        }
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as AnyObject
        }
        query[kSecAttrAccessible as String] = accessible.keychainKey
        return query
    }
}
