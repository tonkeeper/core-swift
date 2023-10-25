//
//  LegacyAPIAssembly.swift
//  
//
//  Created by Grigory Serebryanyy on 25.10.2023.
//

import Foundation

final class LegacyAPIAssembly {
    // MARK: - Internal

    var legacyAPI: LegacyAPI {
        LegacyAPI(urlSession: .shared,
                  host: apiV1URL,
                  configurationProvider: DefaultConfigurationProvider())
    }
    
    var apiV1URL: URL {
        URL(string: "https://api.tonkeeper.com")!
    }
}

