//
//  RemoteConfiguration.swift
//  
//
//  Created by Grigory on 20.6.23..
//

import Foundation
import TonAPI

public struct RemoteConfiguration: Equatable {
    public let tonapiV2Endpoint: String
    public let tonapiTestnetHost: String
    public let tonApiV2Key: String
    public let mercuryoSecret: String?
    
    enum CodingKeys: String, CodingKey {
        case tonapiV2Endpoint
        case tonapiTestnetHost
        case tonApiV2Key
        case mercuryoSecret
    }
}

extension RemoteConfiguration: Codable {}

extension RemoteConfiguration {
    static var empty: RemoteConfiguration {
        RemoteConfiguration(
            tonapiV2Endpoint: "",
            tonapiTestnetHost: "",
            tonApiV2Key: "",
            mercuryoSecret: nil
        )
    }
}
