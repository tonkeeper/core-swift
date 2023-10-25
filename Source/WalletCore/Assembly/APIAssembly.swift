//
//  APIAssembly.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation
import TonAPI
import TonStreamingAPI
import StreamURLSessionTransport
import EventSource
import OpenAPIRuntime

final class APIAssembly {
    let coreAssembly: CoreAssembly
    
    // MARK: - Private properties
    
    // MARK: - Init
    
    init(coreAssembly: CoreAssembly) {
        self.coreAssembly = coreAssembly
    }
    
    // MARK: - Internal
    
    var api: API {
        API(tonAPIClient: tonAPIClient())
    }
    
    var legacyAPI: LegacyAPI {
        LegacyAPI(urlSession: .shared,
                  host: apiV1URL,
                  configurationProvider: DefaultConfigurationProvider())
    }
    
    private var _tonAPIClient: TonAPI.Client?
    func tonAPIClient() -> TonAPI.Client {
        if let tonAPIClient = _tonAPIClient {
            return tonAPIClient
        }
        let tonAPIClient = TonAPI.Client(
            serverURL: tonAPIURL,
            transport: transport,
            middlewares: [authTokenProvider])
        _tonAPIClient = tonAPIClient
        return tonAPIClient
    }
    
    private var _streamingTonAPIClient: TonStreamingAPI.Client?
    func streamingTonAPIClient() -> TonStreamingAPI.Client {
        if let streamingTonAPIClient = _streamingTonAPIClient {
            return streamingTonAPIClient
        }
        let streamingTonAPIClient = TonStreamingAPI.Client(
            serverURL: tonAPIURL,
            transport: transport,
            middlewares: [authTokenProvider])
        _streamingTonAPIClient = streamingTonAPIClient
        return streamingTonAPIClient
    }
    
    // MARK: - Private
    
    private lazy var transport: StreamURLSessionTransport = {
        StreamURLSessionTransport(urlSessionConfiguration: urlSessionConfiguration)
    }()
    
    private lazy var streamingTransport: StreamURLSessionTransport = {
        StreamURLSessionTransport(urlSessionConfiguration: streamingUrlSessionConfiguration)
    }()
    
    private var urlSessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 20
        return configuration
    }
    
    private var streamingUrlSessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval(Int.max)
        configuration.timeoutIntervalForResource = TimeInterval(Int.max)
        return configuration
    }
    
    private var authTokenProvider: AuthTokenProvider {
        AuthTokenProvider()
    }
    
    var tonAPIURL: URL {
        URL(string: "https://keeper.tonapi.io")!
    }
    
    var apiV1URL: URL {
        URL(string: "https://api.tonkeeper.com")!
    }
}
