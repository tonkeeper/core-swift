//
//  APIAssembly.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation
import TonAPI

final class APIAssembly {
    
    let coreAssembly: CoreAssembly
    
    init(coreAssembly: CoreAssembly) {
        self.coreAssembly = coreAssembly
    }
    
    func apiV2(requestInterceptors: [RequestInterceptor]) -> API {
        DefaultAPI(transport: transport(requestInterceptors: requestInterceptors),
                   baseURL: apiV2URL,
                   responseDecoder: responseDecoder)
    }
    
    func apiV1() -> API {
        DefaultAPI(transport: transport(requestInterceptors: []),
                   baseURL: apiV1URL,
                   responseDecoder: responseDecoder)
    }
}

private extension APIAssembly {
    func transport(requestInterceptors: [RequestInterceptor]) -> URLSessionTransport {
        URLSessionTransport(urlSession: urlSession,
                            urlRequestBuilder: urlRequestBuilder,
                            responseBuilder: responseBuilder,
                            requestInterceptors: requestInterceptors)
    }
    
    var urlSession: URLSession {
        .shared
    }
    var urlRequestBuilder: URLRequestBuilder {
        URLRequestBuilder()
    }
    
    var responseBuilder: ResponseBuilder {
        ResponseBuilder()
    }
    
    var responseDecoder: APIResponseDecoder {
        APIResponseDecoder(jsonDecoder: coreAssembly.decoder)
    }
    
    var apiV2URL: URL {
        URL(string: "https://tonapi.io")!
    }
    
    var apiV1URL: URL {
        URL(string: "https://api.tonkeeper.com/keys")!
    }
}
