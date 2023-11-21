//
//  AccessTokenProvider.swift
//  
//
//  Created by Grigory on 21.6.23..
//

import Foundation
import TonAPI
import OpenAPIRuntime
import HTTPTypes

final class AuthTokenProvider: ClientMiddleware {
    private let configurationController: ConfigurationController
    
    init(configurationController: ConfigurationController) {
        self.configurationController = configurationController
    }
    
    func intercept(_ request: HTTPTypes.HTTPRequest,
                   body: OpenAPIRuntime.HTTPBody?,
                   baseURL: URL,
                   operationID: String,
                   next: @Sendable (HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, URL)
                   async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?))
    async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
        var mutableRequest = request
        let configuration = await configurationController.configuration
        mutableRequest
            .headerFields
            .append(
                .init(name: .authorization,
                      value: "Bearer \(configuration.tonApiV2Key)")
            )
        return try await next(mutableRequest, body, baseURL)
    }
}
