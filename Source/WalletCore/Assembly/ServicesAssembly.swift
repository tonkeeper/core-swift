//
//  ServicesAssembly.swift
//  
//
//  Created by Grigory on 22.8.23..
//

import Foundation
import TonAPI

struct ServicesAssembly {
    let tonAPI: API
    let tonkeeperAPI: API
    let coreAssembly: CoreAssembly
    let cacheURL: URL
    
    var collectiblesService: CollectiblesService {
        CollectiblesServiceImplementation(api: tonAPI, localRepository: localRepository())
    }
}

private extension ServicesAssembly {
    func localRepository<T: LocalStorable>() -> any LocalRepository<T> {
        LocalDiskRepository(fileManager: coreAssembly.fileManager,
                            directory: cacheURL,
                            encoder: coreAssembly.encoder,
                            decoder: coreAssembly.decoder)
    }
}
