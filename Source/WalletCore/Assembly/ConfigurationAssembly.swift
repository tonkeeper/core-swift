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
    let apiAssembly: APIAssembly
    let cacheURL: URL
    
    init(coreAssembly: CoreAssembly,
         apiAssembly: APIAssembly,
         cacheURL: URL) {
        self.coreAssembly = coreAssembly
        self.apiAssembly = apiAssembly
        self.cacheURL = cacheURL
    }
 
    func configurationController() -> ConfigurationController {
        ConfigurationController(loader: configurationLoader(),
                                defaultConfigurationProvider: defaultConfigurationProvider(),
                                cacheConfigurationProvider: cacheConfigurationProvider())
    }
    
}

private extension ConfigurationAssembly {
    func configurationLoader() -> ConfigurationLoader {
        ConfigurationLoader(api: apiAssembly.legacyAPI)
    }
    
    func defaultConfigurationProvider() -> ConfigurationProvider {
        DefaultConfigurationProvider()
    }
    
    func cacheConfigurationProvider() -> CacheConfigurationProvider {
        DefaultCacheConfigurationProvider(cachePath: cacheURL, fileManager: coreAssembly.fileManager)
    }
}
