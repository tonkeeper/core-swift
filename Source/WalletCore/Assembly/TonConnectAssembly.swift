//
//  TonConnectAssembly.swift
//  
//
//  Created by Grigory Serebryanyy on 25.10.2023.
//

import Foundation

struct TonConnectAssembly {
    private let coreAssembly: CoreAssembly
    private let apiAssembly: APIAssembly
    private let keeperAssembly: KeeperAssembly
    private let keychainGroup: String
    
    init(coreAssembly: CoreAssembly,
         apiAssembly: APIAssembly,
         keeperAssembly: KeeperAssembly,
         keychainGroup: String) {
        self.coreAssembly = coreAssembly
        self.apiAssembly = apiAssembly
        self.keeperAssembly = keeperAssembly
        self.keychainGroup = keychainGroup
    }
    
    func tonConnectDeeplinkProcessor() -> TonConnectDeeplinkProcessor {
        TonConnectDeeplinkProcessor(manifestLoader: manifestLoader)
    }
    
    func tonConnectController(parameters: TCParameters,
                              manifest: TonConnectManifest) -> TonConnectController {
        TonConnectController(
            parameters: parameters,
            manifest: manifest,
            apiClient: apiAssembly.tonConnectAPIClient(),
            walletProvider: keeperAssembly.keeperController,
            keychainManager: coreAssembly.keychainManager,
            keychainGroup: keychainGroup
        )
    }
}

private extension TonConnectAssembly {
    var manifestLoader: TonConnectManifestLoader {
        TonConnectManifestLoader(urlSession: urlSession)
    }
    
    var urlSession: URLSession {
        URLSession(configuration: urlSessionConfiguration)
    }
    
    var urlSessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 60
        return configuration
    }
}
