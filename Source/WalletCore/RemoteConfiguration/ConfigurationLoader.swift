//
//  ConfigurationLoader.swift
//  
//
//  Created by Grigory on 20.6.23..
//

import Foundation
import TonAPI

actor ConfigurationLoader {
    enum State {
        case none
        case isLoading(Task<RemoteConfiguration, Swift.Error>)
    }
    
    // MARK: - Dependecies
    
    private let api: API
    
    // MARK: - State
    
    var state: State = .none
    
    // MARK: - Init
    
    init(api: API) {
        self.api = api
    }
    
    // MARK: - Fetch
    
    func fetch() async throws -> RemoteConfiguration {
        switch state {
        case .none:
            let task = loadConfigurationTask()
            state = .isLoading(task)
            do {
                let value = try await task.value
                state = .none
                return value
            } catch {
                state = .none
                throw error
            }
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
