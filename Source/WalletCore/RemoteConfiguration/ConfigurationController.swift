//
//  ConfigurationController.swift
//  
//
//  Created by Grigory on 20.6.23..
//

import Foundation
import TonAPI

protocol ConfigurationControllerObserver: AnyObject {
    func configurationControllerDidUpdateConfigutation(_ configurationController: ConfigurationController)
}

actor ConfigurationController {
    enum State {
        case none
        case isLoading
    }
    
    private class WeakObserver {
        weak var value: ConfigurationControllerObserver?
        init(value: ConfigurationControllerObserver?) {
            self.value = value
        }
    }
    
    // MARK: - Dependencies
    
    private let loader: ConfigurationLoader
    private let defaultConfigurationProvider: ConfigurationProvider
    private let cacheConfigurationProvider: CacheConfigurationProvider
    
    // MARK: - State
    
    var configuration: RemoteConfiguration {
        get async {
            func defaultOrCachedConfiguration() async -> RemoteConfiguration {
                guard let _configuration = _configuration else {
                    do { return try defaultConfigurationProvider.configuration }
                    catch { return .empty }
                }
                return _configuration
            }
            switch await loader.state {
            case .isLoading(let task):
                do {
                    return try await task.value
                } catch {
                    return await defaultOrCachedConfiguration()
                }
            case .none:
                return await defaultOrCachedConfiguration()
            }
        }
    }
        
    private var state: State = .none
    private var observers = [WeakObserver]()
    private var attemptNumber = 0
    private var _configuration: RemoteConfiguration? {
        try? cacheConfigurationProvider.configuration
    }
    
    // MARK: - Init
    
    init(loader: ConfigurationLoader,
         defaultConfigurationProvider: ConfigurationProvider,
         cacheConfigurationProvider: CacheConfigurationProvider) {
        self.loader = loader
        self.defaultConfigurationProvider = defaultConfigurationProvider
        self.cacheConfigurationProvider = cacheConfigurationProvider
    }
    
    func loadConfiguration() async -> RemoteConfiguration {
        do {
            let configuration = try await loader.fetch()
            try? cacheConfigurationProvider.saveConfiguration(configuration)
            notify()
            return configuration
        } catch {
            attemptNumber += 1
            guard attemptNumber < .maxLoadConfigurationAttempt else {
                return await configuration
            }
            return await loadConfiguration()
        }
    }
    
    // MARK: - Observers
    
    func addObserver(_ observer: ConfigurationControllerObserver) {
        removeNilObservers()
        observers.append(.init(value: observer))
    }
    
    func removeObserver(_ observer: ConfigurationControllerObserver) {
        removeNilObservers()
        guard let index = observers
            .firstIndex(where: { $0.value === observer }) else { return }
        observers.remove(at: index)
    }
}

private extension ConfigurationController {
    func removeNilObservers() {
        observers = observers.filter { $0.value != nil }
    }
    
    func notify() {
        observers.forEach {
            $0.value?.configurationControllerDidUpdateConfigutation(self)
        }
    }
}

private extension Int {
    static let maxLoadConfigurationAttempt = 3
}
