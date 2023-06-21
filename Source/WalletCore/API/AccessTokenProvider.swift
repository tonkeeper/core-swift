//
//  AccessTokenProvider.swift
//  
//
//  Created by Grigory on 21.6.23..
//

import Foundation
import TonAPI

final class AccessTokenProvider: RequestInterceptor {
    
    // MARK: - Dependencies
    
    private let configurationController: ConfigurationController

    // MARK: - Init
    
    init(configurationController: ConfigurationController) {
        self.configurationController = configurationController
    }
    
    // MARK: - RequestInterceptor
    
    func intercept(request: Request) async throws -> Request {
        var request = request
        let configuration = await configurationController.configuration
        request.headers.append(.init(name: .authorizatioName, value: "\(String.bearer) \(configuration.tonApiV2Key)"))
        return request
    }
}

private extension String {
    static let authorizatioName = "Authorization"
    static let bearer = "Bearer"
}
