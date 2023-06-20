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
        case cached
    }
    
    private class WeakObserver {
        weak var value: ConfigurationControllerObserver?
        init(value: ConfigurationControllerObserver?) {
            self.value = value
        }
    }
    
    // MARK: - Dependencies
    
    private let loader: ConfigurationLoader
    
    // MARK: - State
    
    private var state: State = .none
    private var observers = [WeakObserver]()
    private var attemptNumber = 0
    private(set) var configuration: RemoteConfiguration {
        didSet {
            notify()
        }
    }
    
    // MARK: - Init
    
    init(loader: ConfigurationLoader) {
        self.loader = loader
        self.configuration = .empty
    }
    
    func loadConfiguration() async -> RemoteConfiguration {
        do {
            let configuration = try await loader.fetch()
            self.configuration = configuration
            return configuration
        } catch {
            attemptNumber += 1
            if attemptNumber < .maxLoadConfigurationAttempt {
                return await loadConfiguration()
            }
            return configuration
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
