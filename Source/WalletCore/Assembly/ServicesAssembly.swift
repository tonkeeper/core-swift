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
    
    init(tonAPI: API, 
         tonkeeperAPI: API,
         streamingAPI: StreamingAPI,
         coreAssembly: CoreAssembly,
         cacheURL: URL) {
        self.tonAPI = tonAPI
        self.tonkeeperAPI = tonkeeperAPI
        self.streamingAPI = streamingAPI
        self.coreAssembly = coreAssembly
        self.cacheURL = cacheURL
    }
    
    var collectiblesService: CollectiblesService {
        CollectiblesServiceImplementation(
            api: tonAPI, 
            localRepository: localRepository()
        )
    }
    
    var dnsService: DNSService {
        DNSServiceImplementation(api: tonAPI)
    }
    
    var fiatMethodsService: FiatMethodsService {
        FiatMethodsServiceImplementation(
            api: tonkeeperAPI,
            localRepository: localRepository()
        )
    }
    
    lazy var transactionsUpdateService: TransactionsUpdateService = {
        TransactionsUpdateServiceImplementation(streamingAPI: streamingAPI)
    }()
}

private extension ServicesAssembly {
    func localRepository<T: LocalStorable>() -> any LocalRepository<T> {
        LocalDiskRepository(fileManager: coreAssembly.fileManager,
                            directory: cacheURL,
                            encoder: coreAssembly.encoder,
                            decoder: coreAssembly.decoder)
    }
}
