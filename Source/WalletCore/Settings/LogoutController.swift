//
//  LogoutController.swift
//
//
//  Created by Grigory on 12.10.23..
//

import Foundation

public final class LogoutController {
    private let cacheURL: URL
    private let sharedKeychainGroup: String
    private let keeperInfoService: KeeperInfoService
    private let fileManager: FileManager
    private let keychainManager: KeychainManager
    
    init(cacheURL: URL,
         keychainGroup: String,
         keeperInfoService: KeeperInfoService,
         fileManager: FileManager,
         keychainManager: KeychainManager) {
        self.cacheURL = cacheURL
        self.sharedKeychainGroup = keychainGroup
        self.keeperInfoService = keeperInfoService
        self.fileManager = fileManager
        self.keychainManager = keychainManager
    }
    
    public func logout() {
        if fileManager.fileExists(atPath: cacheURL.path) {
            try? fileManager.removeItem(at: cacheURL)
        }
        
        try? keeperInfoService.removeKeeperInfo()
        try? keychainManager.deleteAll(group: sharedKeychainGroup)
    }
}
