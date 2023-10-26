//
//  TCRequestPayload.swift
//  
//
//  Created by Grigory Serebryanyy on 18.10.2023.
//

import Foundation

struct TCRequestPayload: Decodable {
    
    enum Item: Decodable {
        case tonAddress
        case tonProof(payload: String)
        case unknown
        
        enum CodingKeys: CodingKey {
            case name
            case payload
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let name = try container.decode(String.self, forKey: .name)
            switch name {
            case "ton_addr":
                self = .tonAddress
            case "ton_proof":
                let payload = try container.decode(String.self, forKey: .payload)
                self = .tonProof(payload: payload)
            default:
                self = .unknown
            }
        }
    }
    
    let manifestUrl: URL
    let items: [Item]
}
