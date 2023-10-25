//
//  SettingsController.swift
//
//
//  Created by Grigory on 3.10.23..
//

import Foundation

public protocol SettingsController: SecuritySettingsController, CurrencySettingsController, SocialLinksSettingsController {
    func addObserver(_ observer: SettingsControllerObserver)
    func removeObserver(_ observer: SettingsControllerObserver)
}

public protocol SecuritySettingsController {
    func getIsBiometryEnabled() -> Bool
    func setIsBiometryEnabled(_ isBiometryEnabled: Bool) throws
}

public protocol CurrencySettingsController {
    func getSelectedCurrency() throws -> Currency
    func getAvailableCurrencies() -> [Currency]
    func setCurrency(_ currency: Currency) throws
}

public protocol SocialLinksSettingsController {
    var supportURL: URL? { get async }
    var contactUsURL: URL? { get async }
    var tonkeeperNews: URL? { get async }
}

public protocol SettingsControllerObserver: AnyObject {
    func didUpdateSettings()
}

public final class SettingsControllerImplementation: SettingsController, SecuritySettingsController {
    struct SettingsControllerObserverWrapper {
      weak var observer: SettingsControllerObserver?
    }

    private let keeperController: KeeperController
    private let configurationController: ConfigurationController
    
    private var observers = [SettingsControllerObserverWrapper]()
    
    init(keeperController: KeeperController,
         configurationController: ConfigurationController) {
        self.keeperController = keeperController
        self.configurationController = configurationController
    }
    
    public func addObserver(_ observer: SettingsControllerObserver) {
      observers.append(.init(observer: observer))
    }
    
    public func removeObserver(_ observer: SettingsControllerObserver) {
      observers = observers.filter { $0.observer !== observer }
    }
    
    // MARK: - Currency
    
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
    
    // MARK: - Biometry
    
    public func getIsBiometryEnabled() -> Bool {
        (try? keeperController.getSecuritySettings().isBiometryEnabled) ?? false
    }
    
    public func setIsBiometryEnabled(_ isBiometryEnabled: Bool) throws {
        let securitySettings = try keeperController
            .getSecuritySettings()
            .setIsBiometryEnabled(isBiometryEnabled)
        try keeperController.setSecuritySettings(securitySettings)
    }
    
    // MARK: - Links
    
    public var supportURL: URL? {
        get async {
            let configuration = await configurationController.configuration
            return URL(string: configuration.directSupportUrl ?? "")
        }
    }
    
    public var contactUsURL: URL? {
        get async {
            let configuration = await configurationController.configuration
            return URL(string: configuration.supportLink ?? "")
        }
    }
    
    public var tonkeeperNews: URL? {
        get async {
            let configuration = await configurationController.configuration
            return URL(string: configuration.tonkeeperNewsUrl ?? "")
        }
    }
}

private extension SettingsControllerImplementation {
  func notifyObservers() {
    observers = observers.filter { $0.observer != nil }
    observers.forEach { $0.observer?.didUpdateSettings() }
  }
}
