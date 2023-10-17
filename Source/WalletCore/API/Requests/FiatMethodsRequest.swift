//
//  FiatMethodsRequest.swift
//
//
//  Created by Grigory on 14.10.23..
//

import Foundation
import TonAPI

struct FiatMethodsRequest: APIRequest {
    typealias Entity = FiatMethodsResponse
    
    var request: Request {
        Request(path: path,
                method: .GET,
                headers: [],
                queryItems: queryItems,
                bodyParameter: [:])
    }
    
    let path = "/fiat/methods"
    var queryItems: [URLQueryItem] {
        [
            .init(name: "lang", value: "en"),
            .init(name: "build", value: "3.4.0"),
            .init(name: "chainName", value: "mainnet")
        ]
    }
}
