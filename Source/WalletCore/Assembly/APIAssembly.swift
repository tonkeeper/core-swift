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
    
    func tonAPI(requestInterceptors: [RequestInterceptor]) -> API {
        DefaultAPI(transport: transport(requestInterceptors: requestInterceptors),
                   baseURL: tonAPIURL,
                   responseDecoder: responseDecoder)
    }
    
    func configurationAPI() -> API {
        DefaultAPI(transport: transport(requestInterceptors: []),
                   baseURL: configurationAPIURL,
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
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        return URLSession(configuration: configuration)
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
    
    var tonAPIURL: URL {
        URL(string: "https://tonapi.io")!
    }
    
    var configurationAPIURL: URL {
        URL(string: "https://api.tonkeeper.com/keys")!
    }
}
