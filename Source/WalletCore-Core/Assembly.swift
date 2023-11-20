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
    
    public init(cacheURL: URL,
                sharedCacheURL: URL,
                sharedKeychainGroup: String) {
        self.cacheURL = cacheURL
        self.sharedCacheURL = sharedCacheURL
        self.sharedKeychainGroup = sharedKeychainGroup
    }
}

public final class Assembly {
    private let dependencies: Dependencies
    
    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    lazy var walletsController = WalletsController(
        keeperInfoService: keeperInfoService,
        walletMnemonicRepository: walletMnemonicRepository
    )
}

private extension Assembly {
    var keeperInfoService: KeeperInfoService {
        KeeperInfoService(keeperInfoRepository: fileSystemVault(url: dependencies.cacheURL))
    }
    
    var walletMnemonicRepository: WalletMnemonicRepository {
        MnemonicVault(keychainVault: keychainVault, accessGroup: dependencies.sharedKeychainGroup)
    }
    
    var keychainVault: KeychainVault {
        KeychainVaultImplementations(keychain: keychain)
    }
    
    var keychain: Keychain {
        KeychainImplementation()
    }
    
    func fileSystemVault<T>(url: URL) -> FileSystemVault<T> {
        FileSystemVault(fileManager: .default, directory: url)
    }
}
