//
//  TonConnectMessage.swift
//  
//
//  Created by Grigory Serebryanyy on 27.10.2023.
//

import Foundation
import TonSwift

public struct TonConnectMessage: Decodable {
    enum Method: String, Decodable {
        case sendTransaction
    }
    
    struct Param: Decodable {
        let messages: [Message]
        let validUntil: TimeInterval
        let from: Address
        
        enum CodingKeys: String, CodingKey {
            case messages
            case validUntil = "valid_until"
            case from
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            messages = try container.decode([Message].self, forKey: .messages)
            validUntil = try container.decode(TimeInterval.self, forKey: .validUntil)
            from = try Address.parse(try container.decode(String.self, forKey: .from))
        }
    }
    
    struct Message: Decodable {
        let address: Address
        let amount: Int64
        
        enum CodingKeys: String, CodingKey {
            case address
            case amount
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            address = try Address.parse(try container.decode(String.self, forKey: .address))
            amount = Int64(try container.decode(String.self, forKey: .amount)) ?? 0
        }
    }
    
    let method: Method
    let params: [Param]
    
    enum CodingKeys: String, CodingKey {
        case method
        case params
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        method = try container.decode(Method.self, forKey: .method)
        let paramsArray = try container.decode([String].self, forKey: .params)
        let jsonDecoder = JSONDecoder()
        params = paramsArray.compactMap {
            guard let data = $0.data(using: .utf8) else { return nil }
            return try? jsonDecoder.decode(Param.self, from: data)
        }
    }
}
