//
//  TonConnectController.swift
//  
//
//  Created by Grigory Serebryanyy on 18.10.2023.
//

import Foundation
import TonSwift

public actor TonConnectController {
    public struct PopUpModel {
        public let name: String
        public let host: String?
        public let wallet: String
        public let revision: String
        public let appImageURL: URL?
    }
    
    private let parameters: TCParameters
    private let manifest: TonConnectManifest
    
    init(parameters: TCParameters,
         manifest: TonConnectManifest) {
        self.parameters = parameters
        self.manifest = manifest
    }
    
    nonisolated
    public func getPopUpModel() -> PopUpModel {
        .init(
            name: manifest.name,
            host: manifest.url.host,
            wallet: "EQF2…G21Z",
            revision: "v4R2",
            appImageURL: manifest.iconUrl
        )
    }
}
