//
//  LoadConfigurationRequest.swift
//  
//
//  Created by Grigory on 20.6.23..
//

import Foundation
import TonAPI

struct LoadConfigurationRequest: APIRequest {
    typealias Entity = RemoteConfiguration
    
    var request: TonAPI.Request {
        Request(
            path: path,
            method: .GET,
            headers: [],
            queryItems: queryItems,
            bodyParameter: [:]
        )
    }
    
    let path = "/keys"
    var queryItems: [URLQueryItem] {
        [
            .init(name: "lang", value: lang),
            .init(name: "build", value: build),
            .init(name: "chainName", value: chainName),
            .init(name: "platform", value: platform),
        ]
    }
    
    let lang: String
    let build: String
    let chainName: String
    let platform: String
    
    init(lang: String,
         build: String,
         chainName: String,
         platform: String) {
        self.lang = lang
        self.build = build
        self.chainName = chainName
        self.platform = platform
    }
}
