//
//  KeeperInfoAssembly.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation

final class KeeperInfoAssembly {
    let coreAssembly: CoreAssembly
    
    init(coreAssembly: CoreAssembly) {
        self.coreAssembly = coreAssembly
    }
    
    func keeperController(cacheURL: URL) -> KeeperController {
        KeeperController(keeperService: keeperInfoService(cacheURL: cacheURL),
                         keychainManager: coreAssembly.keychainManager)
    }
}

private extension KeeperInfoAssembly {
    func localRepository(cacheURL: URL) -> any LocalRepository<Rates> {
        return LocalDiskRepository(fileManager: coreAssembly.fileManager,
                                   directory: cacheURL,
                                   encoder: coreAssembly.encoder,
                                   decoder: coreAssembly.decoder)
    }
    
    func keeperInfoService(cacheURL: URL) -> KeeperInfoService {
        KeeperInfoServiceImplementation(localRepository: keeperInfoLocalRepository(cacheURL: cacheURL))
    }
    
    func keeperInfoLocalRepository(cacheURL: URL) -> any LocalRepository<KeeperInfo> {
        LocalDiskRepository(fileManager: coreAssembly.fileManager,
                            directory: cacheURL,
                            encoder: coreAssembly.encoder,
                            decoder: coreAssembly.decoder)
    }
}
