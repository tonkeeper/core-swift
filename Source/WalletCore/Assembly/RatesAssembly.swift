//
//  RatesAssembly.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation
import TonAPI

final class RatesAssembly {
    let coreAssembly: CoreAssembly
    
    init(coreAssembly: CoreAssembly) {
        self.coreAssembly = coreAssembly
    }
    
    func ratesService(api: API, cacheURL: URL) -> RatesService {
        RatesServiceImplementation(api: api, localRepository: localRepository(cacheURL: cacheURL))
    }
}

private extension RatesAssembly {
    func localRepository(cacheURL: URL) -> any LocalRepository<Rates> {
        return LocalDiskRepository(fileManager: coreAssembly.fileManager,
                                   directory: cacheURL,
                                   encoder: coreAssembly.encoder,
                                   decoder: coreAssembly.decoder)
    }
}
