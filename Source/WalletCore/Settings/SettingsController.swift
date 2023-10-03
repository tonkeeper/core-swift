//
//  SettingsController.swift
//
//
//  Created by Grigory on 3.10.23..
//

import Foundation

public protocol SettingsControllerObserver: AnyObject {
    func didUpdateSettings()
}

public final class SettingsController {
    
    struct SettingsControllerObserverWrapper {
      weak var observer: SettingsControllerObserver?
    }

    private let keeperController: KeeperController
    
    private var observers = [SettingsControllerObserverWrapper]()
    
    init(keeperController: KeeperController) {
        self.keeperController = keeperController
    }
    
    public func addObserver(_ observer: SettingsControllerObserver) {
      observers.append(.init(observer: observer))
    }
    
    public func removeObserver(_ observer: SettingsControllerObserver) {
      observers = observers.filter { $0.observer !== observer }
    }
    
    public func getSelectedCurrency() throws -> Currency {
        try keeperController.activeWallet.currency
    }
    
    public func getAvailableCurrencies() -> [Currency] {
        Currency.allCases
    }
    
    public func setCurrency(_ currency: Currency) throws {
        try keeperController.update(wallet: try keeperController.activeWallet, currency: currency)
        notifyObservers()
    }
}

private extension SettingsController {
  func notifyObservers() {
    observers = observers.filter { $0.observer != nil }
    observers.forEach { $0.observer?.didUpdateSettings() }
  }
}
