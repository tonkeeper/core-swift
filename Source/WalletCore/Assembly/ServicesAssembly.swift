//
//  ServicesAssembly.swift
//  
//
//  Created by Grigory on 22.8.23..
//

import Foundation
import TonAPI

final class ServicesAssembly {
    let tonAPI: API
    let tonkeeperAPI: API
    let streamingAPI: StreamingAPI
    let coreAssembly: CoreAssembly
    let cacheURL: URL
    let sharedCacheURL: URL
    
    init(tonAPI: API, 
         tonkeeperAPI: API,
         streamingAPI: StreamingAPI,
         coreAssembly: CoreAssembly,
         cacheURL: URL,
         sharedCacheURL: URL) {
        self.tonAPI = tonAPI
        self.tonkeeperAPI = tonkeeperAPI
        self.streamingAPI = streamingAPI
        self.coreAssembly = coreAssembly
        self.cacheURL = cacheURL
        self.sharedCacheURL = sharedCacheURL
    }
    
    var collectiblesService: CollectiblesService {
        CollectiblesServiceImplementation(
            api: tonAPI, 
            localRepository: localRepository(cacheURL: cacheURL)
        )
    }
    
    var dnsService: DNSService {
        DNSServiceImplementation(api: tonAPI)
    }
    
    var fiatMethodsService: FiatMethodsService {
        FiatMethodsServiceImplementation(
            api: tonkeeperAPI,
            localRepository: localRepository(cacheURL: cacheURL)
        )
    }
    
    var keeperInfoService: KeeperInfoService {
        KeeperInfoServiceImplementation(localRepository: localRepository(cacheURL: sharedCacheURL))
    }
    
    lazy var transactionsUpdateService: TransactionsUpdateService = {
        TransactionsUpdateServiceImplementation(streamingAPI: streamingAPI)
    }()
}

private extension ServicesAssembly {
    func localRepository<T: LocalStorable>(cacheURL: URL) -> any LocalRepository<T> {
        LocalDiskRepository(fileManager: coreAssembly.fileManager,
                            directory: cacheURL,
                            encoder: coreAssembly.encoder,
                            decoder: coreAssembly.decoder)
    }
}
