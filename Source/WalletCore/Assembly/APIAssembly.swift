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
        DefaultAPI(networkClient: networkClient(requestInterceptors: requestInterceptors),
                   baseURL: tonAPIURL,
                   responseDecoder: responseDecoder)
    }
    
    func configurationAPI() -> API {
        DefaultAPI(networkClient: networkClient(requestInterceptors: []),
                   baseURL: configurationAPIURL,
                   responseDecoder: responseDecoder)
    }
    
    func streamingAPI(requestInterceptors: [RequestInterceptor]) -> StreamingAPI {
        DefaultStreamingAPI(eventSource: eventSource(requestInterceptors: requestInterceptors),
                            baseURL: tonAPIURL,
                            decoder: streamingResponseDecoder)
    }
}

private extension APIAssembly {
    func networkClient(requestInterceptors: [RequestInterceptor]) -> NetworkClient {
        NetworkClient(httpTransport: transport(),
                      urlRequestBuilder: urlRequestBuilder,
                      requestInterceptors: requestInterceptors)
    }

    func transport() -> HTTPTransport {
        URLSessionHTTPTransport(urlSessionConfiguration: tonAPIConfiguration)
    }
    
    func eventSource(requestInterceptors: [RequestInterceptor]) -> EventSource {
        EventSource(networkClient: networkClient(requestInterceptors: requestInterceptors))
    }
    
    var tonAPIConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        return configuration
    }
    
    var urlRequestBuilder: URLRequestBuilder {
        URLRequestBuilder()
    }
    
    var responseDecoder: APIResponseDecoder {
        APIResponseDecoder(jsonDecoder: coreAssembly.decoder)
    }
    
    var streamingResponseDecoder: StreamingAPIDecoder {
        StreamingAPIDecoder(jsonDecoder: coreAssembly.decoder)
    }
    
    var tonAPIURL: URL {
        URL(string: "https://tonapi.io")!
    }
    
    var configurationAPIURL: URL {
        URL(string: "https://api.tonkeeper.com")!
    }
}
