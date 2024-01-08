//
//  LogoutController.swift
//
//
//  Created by Grigory on 12.10.23..
//

import Foundation
import WalletCoreCore

public final class LogoutController {
    private let cacheURL: URL
    private let sharedKeychainGroup: String
    private let keeperInfoService: KeeperInfoService
    private let fileManager: FileManager
    private let keychainVault: KeychainVault
    
    init(cacheURL: URL,
         keychainGroup: String,
         keeperInfoService: KeeperInfoService,
         fileManager: FileManager,
         keychainVault: KeychainVault) {
        self.cacheURL = cacheURL
        self.sharedKeychainGroup = keychainGroup
        self.keeperInfoService = keeperInfoService
        self.fileManager = fileManager
        self.keychainVault = keychainVault
    }
    
    public func logout() {
        if fileManager.fileExists(atPath: cacheURL.path) {
            try? fileManager.removeItem(at: cacheURL)
        }
        
        try? keeperInfoService.deleteKeeperInfo()
        try? keychainVault.deleteItem(DeleteAll(group: sharedKeychainGroup))
        try? keychainVault.deleteItem(DeleteAll(group: nil))
    }
    
    private struct DeleteAll: WalletCoreCore.KeychainQueryable {
        let group: String?
        var query: [String : AnyObject] {
            var query = [String: AnyObject]()
            query[kSecClass as String] = kSecClassGenericPassword
            if let group = group {
                query[kSecAttrAccessGroup as String] = group as AnyObject
            }
            return query
        }
    }
}
