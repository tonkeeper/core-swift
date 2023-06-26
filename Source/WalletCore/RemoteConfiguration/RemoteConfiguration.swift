//
//  RemoteConfiguration.swift
//  
//
//  Created by Grigory on 20.6.23..
//

import Foundation
import TonAPI

struct RemoteConfiguration: Equatable {
    let tonapiV2Endpoint: String
    let tonapiTestnetHost: String
    let tonApiV2Key: String
    
    enum CodingKeys: String, CodingKey {
        case tonapiV2Endpoint
        case tonapiTestnetHost
        case tonApiV2Key
    }
}

extension RemoteConfiguration: Codable {}

extension RemoteConfiguration {
    static var empty: RemoteConfiguration {
        RemoteConfiguration(
            tonapiV2Endpoint: "",
            tonapiTestnetHost: "",
            tonApiV2Key: ""
        )
    }
}
