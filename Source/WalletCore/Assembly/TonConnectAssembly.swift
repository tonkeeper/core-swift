//
//  TonConnectAssembly.swift
//  
//
//  Created by Grigory Serebryanyy on 25.10.2023.
//

import Foundation

final class TonConnectAssembly {
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
    
    func tonConnectController(parameters: TonConnectParameters,
                              manifest: TonConnectManifest) -> TonConnectController {
        let controller = TonConnectController(
            parameters: parameters,
            manifest: manifest,
            apiClient: apiAssembly.tonConnectAPIClient(),
            walletProvider: keeperAssembly.keeperController,
            appsVault: appsVault,
            keychainManager: coreAssembly.keychainManager,
            keychainGroup: keychainGroup
        )
        Task { await controller.addObserver(tonConnectEventsDaemon) }
        return controller
    }
    
    lazy var tonConnectEventsDaemon: TonConnectEventsDaemon = {
        TonConnectEventsDaemon(
            walletProvider: keeperAssembly.keeperController,
            appsVault: appsVault,
            apiClient: apiAssembly.tonConnectAPIClient())
    }()
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
    
    var appsVault: TonConnectAppsVault {
        TonConnectAppsVault(
            keychainManager: coreAssembly.keychainManager,
            keychainGroup: keychainGroup
        )
    }
}
