//
//  LogoutController.swift
//
//
//  Created by Grigory on 12.10.23..
//

import Foundation

public final class LogoutController {
    private let cacheURL: URL
    private let sharedCacheURL: URL
    private let sharedKeychainGroup: String
    private let fileManager: FileManager
    private let keychainManager: KeychainManager
    
    init(cacheURL: URL,
         sharedCahedURL: URL,
         keychainGroup: String,
         fileManager: FileManager,
         keychainManager: KeychainManager) {
        self.cacheURL = cacheURL
        self.sharedCacheURL = sharedCahedURL
        self.sharedKeychainGroup = keychainGroup
        self.fileManager = fileManager
        self.keychainManager = keychainManager
    }
    
    public func logout() {
        if fileManager.fileExists(atPath: cacheURL.path) {
            try? fileManager.removeItem(at: cacheURL)
        }
        if fileManager.fileExists(atPath: sharedCacheURL.path) {
            try? fileManager.removeItem(at: sharedCacheURL)
        }
        try? keychainManager.deleteAll(group: sharedKeychainGroup)
    }
}
