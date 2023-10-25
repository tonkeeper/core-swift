//
//  TonConnectAssembly.swift
//  
//
//  Created by Grigory Serebryanyy on 25.10.2023.
//

import Foundation

struct TonConnectAssembly {
    func tonConnectDeeplinkProcessor() -> TonConnectDeeplinkProcessor {
        TonConnectDeeplinkProcessor(manifestLoader: manifestLoader)
    }
    
    func tonConnectController(parameters: TCParameters,
                              manifest: TonConnectManifest) -> TonConnectController {
        TonConnectController(
            parameters: parameters,
            manifest: manifest
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
