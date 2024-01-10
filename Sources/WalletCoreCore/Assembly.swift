//
//  Assembly.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation

public struct Dependencies {
    public let cacheURL: URL
    public let sharedCacheURL: URL
    public let sharedKeychainGroup: String
    public let oldSharedCacheURL: URL
    public let oldSharedKeychainGroup: String
    
    public init(cacheURL: URL,
                sharedCacheURL: URL,
                sharedKeychainGroup: String,
                oldSharedCacheURL: URL,
                oldSharedKeychainGroup: String) {
        self.cacheURL = cacheURL
        self.sharedCacheURL = sharedCacheURL
        self.sharedKeychainGroup = sharedKeychainGroup
        self.oldSharedCacheURL = oldSharedCacheURL
        self.oldSharedKeychainGroup = oldSharedKeychainGroup
    }
}

public final class Assembly {
    private let dependencies: Dependencies
    
    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    public lazy var walletsController = WalletsController(
        keeperInfoService: keeperInfoService,
        walletMnemonicRepository: walletMnemonicRepository
    )
    
    public var walletProvider: WalletProvider {
        walletsController
    }
    
    public var passcodeController: PasscodeController {
        PasscodeController(passcodeVault: passcodeVault)
    }
    
    public var securityController: SecurityController {
        SecurityController(keeperInfoService: keeperInfoService)
    }
    
    public var walletMnemonicRepository: WalletMnemonicRepository {
        MnemonicVault(keychainVault: keychainVault, accessGroup: dependencies.sharedKeychainGroup)
    }
    
    public var passcodeVault: PasscodeVault {
        PasscodeVault(keychainVault: keychainVault)
    }
    
    public var fileManager: FileManager {
        .default
    }
    
    public var keychainVault: KeychainVault {
        KeychainVaultImplementations(keychain: keychain)
    }
    
    public lazy var keeperInfoService: KeeperInfoService = {
        KeeperInfoService(keeperInfoRepository: sharedFileSystemVault())
    }()
    
    func fileSystemVault<T>() -> FileSystemVault<T> {
        FileSystemVault(fileManager: .default, directory: dependencies.cacheURL)
    }
    
    func sharedFileSystemVault<T>() -> FileSystemVault<T> {
        FileSystemVault(fileManager: .default, directory: dependencies.sharedCacheURL)
    }
    
    func oldSharedFileSystemVault<T>() -> FileSystemVault<T> {
        FileSystemVault(fileManager: .default, directory: dependencies.oldSharedCacheURL)
    }
    
    public lazy var oldAppMigration: OldAppMigration =  {
        OldAppMigration(
            keeperInfoService: keeperInfoService, 
            oldKeeperInfoService: KeeperInfoService(keeperInfoRepository: oldSharedFileSystemVault()),
            mnemonicRepository: walletMnemonicRepository,
            oldMnemonicRepository: MnemonicVault(keychainVault: keychainVault, accessGroup: dependencies.oldSharedKeychainGroup)
        )
    }()
}

private extension Assembly {
    var keychain: Keychain {
        KeychainImplementation()
    }
}
