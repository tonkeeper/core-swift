//
//  ConfigurationLoader.swift
//  
//
//  Created by Grigory on 20.6.23..
//

import Foundation
import TonAPI

actor ConfigurationLoader {
    enum Status {
        case none
        case isLoading(Task<RemoteConfiguration, Swift.Error>)
    }
    
    // MARK: - Dependecies
    
    private let api: API
    
    // MARK: - State
    
    private var status: Status = .none
    
    // MARK: - Init
    
    init(api: API) {
        self.api = api
    }
    
    // MARK: - Fetch
    
    func fetch() async throws -> RemoteConfiguration {
        switch status {
        case .none:
            let task = loadConfigurationTask()
            status = .isLoading(task)
            let value = try await task.value
            status = .none
            return value
        case .isLoading(let task):
            let configuration = try await task.value
            return configuration
        }
    }
}

private extension ConfigurationLoader {
    func loadConfigurationTask() -> Task<RemoteConfiguration, Swift.Error> {
        let request = LoadConfigurationRequest(
            lang: .lang,
            build: .build,
            chainName: .chainName,
            platform: .platform
        )
        return Task {
            do {
                let response = try await api.send(request: request)
                return response.entity
            } catch {
                throw error
            }
        }
    }
}

private extension String {
    static let lang = "en"
    static let build = "3.0.0"
    static let chainName = "mainnet"
    static let platform = "ios"
}
