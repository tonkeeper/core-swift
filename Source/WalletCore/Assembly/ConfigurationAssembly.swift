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
    let legacyAPIAssembly: LegacyAPIAssembly
    let cacheURL: URL
    
    init(coreAssembly: CoreAssembly,
         legacyAPIAssembly: LegacyAPIAssembly,
         cacheURL: URL) {
        self.coreAssembly = coreAssembly
        self.legacyAPIAssembly = legacyAPIAssembly
        self.cacheURL = cacheURL
    }
 
    func configurationController() -> ConfigurationController {
        ConfigurationController(loader: configurationLoader,
                                defaultConfigurationProvider: defaultConfigurationProvider(),
                                cacheConfigurationProvider: cacheConfigurationProvider())
    }
    
    private lazy var configurationLoader = ConfigurationLoader(api: legacyAPIAssembly.legacyAPI)
}

private extension ConfigurationAssembly {
    
    
    func defaultConfigurationProvider() -> ConfigurationProvider {
        DefaultConfigurationProvider()
    }
    
    func cacheConfigurationProvider() -> CacheConfigurationProvider {
        DefaultCacheConfigurationProvider(cachePath: cacheURL, fileManager: coreAssembly.fileManager)
    }
}
