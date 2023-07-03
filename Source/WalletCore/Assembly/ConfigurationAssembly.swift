//
//  ConfigurationAssembly.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation
import TonAPI

final class ConfigurationAssembly {
    
    let coreAssembly: CoreAssembly
    
    init(coreAssembly: CoreAssembly) {
        self.coreAssembly = coreAssembly
    }
 
    func configurationController(api: API, cacheURL: URL) -> ConfigurationController {
        ConfigurationController(loader: configurationLoader(api: api),
                                defaultConfigurationProvider: defaultConfigurationProvider(),
                                cacheConfigurationProvider: cacheConfigurationProvider(cacheURL: cacheURL))
    }
    
}

private extension ConfigurationAssembly {
    func configurationLoader(api: API) -> ConfigurationLoader {
        ConfigurationLoader(api: api)
    }
    
    func defaultConfigurationProvider() -> ConfigurationProvider {
        DefaultConfigurationProvider()
    }
    
    func cacheConfigurationProvider(cacheURL: URL) -> CacheConfigurationProvider {
        DefaultCacheConfigurationProvider(cachePath: cacheURL, fileManager: coreAssembly.fileManager)
    }
    
}
