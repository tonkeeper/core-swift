//
//  TonConnectDeeplinkProcessor.swift
//  
//
//  Created by Grigory Serebryanyy on 26.10.2023.
//

import Foundation

public struct TonConnectDeeplinkProcessor {
    enum Error: Swift.Error {
        case manifestLoadFailed
    }
    
    private let manifestLoader: TonConnectManifestLoader
    
    init(manifestLoader: TonConnectManifestLoader) {
        self.manifestLoader = manifestLoader
    }
    
    public func processDeeplink(_ deeplink: TonConnectDeeplink) async throws -> (TCParameters, TonConnectManifest) {
        let parameters = try TCUrlParser().parseString(deeplink.string)
        do {
            let manifest = try await manifestLoader
                .loadManifest(manifestURL: parameters.requestPayload.manifestUrl)
            return (parameters, manifest)
        } catch {
            throw Error.manifestLoadFailed
        }
    }
}
