//
//  WalletCoreAssembly.swift
//  
//
//  Created by Grigory on 28.6.23..
//

import Foundation

struct WalletCoreAssembly {
    init() {}
    
    func keeperController(url: URL) -> KeeperController {
        KeeperController(keeperService: keeperInfoService(url: url),
                         keychainManager: keychainManager)
    }
}

private extension WalletCoreAssembly {
    var keychainManager: KeychainManager {
        KeychainManager(keychain: keychain)
    }
    
    var keychain: Keychain {
        KeychainImplementation()
    }
    
    func keeperInfoService(url: URL) -> KeeperInfoService {
        KeeperInfoServiceImplementation(localRepository: keeperInfoLocalRepository(url: url))
    }
    
    func keeperInfoLocalRepository(url: URL) -> any LocalRepository<KeeperInfo> {
        LocalDiskRepository(fileManager: self.fileManager,
                            directory: url,
                            encoder: self.encoder,
                            decoder: self.decoder)
    }
    
    var fileManager: FileManager {
        .default
    }
    
    var encoder: JSONEncoder {
        JSONEncoder()
    }
    
    var decoder: JSONDecoder {
        JSONDecoder()
    }
}
