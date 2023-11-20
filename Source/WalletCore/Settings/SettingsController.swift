//
//  SettingsController.swift
//
//
//  Created by Grigory on 3.10.23..
//

import Foundation
import WalletCoreCore

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

    private let walletProvider: WalletProvider
    private let securityController: SecurityController
    private let configurationController: ConfigurationController
    private let keeperInfoService: KeeperInfoService
    
    private var observers = [SettingsControllerObserverWrapper]()
    
    init(walletProvider: WalletProvider,
         securityController: SecurityController,
         configurationController: ConfigurationController,
         keeperInfoService: KeeperInfoService) {
        self.walletProvider = walletProvider
        self.securityController = securityController
        self.configurationController = configurationController
        self.keeperInfoService = keeperInfoService
    }
    
    public func addObserver(_ observer: SettingsControllerObserver) {
      observers.append(.init(observer: observer))
    }
    
    public func removeObserver(_ observer: SettingsControllerObserver) {
      observers = observers.filter { $0.observer !== observer }
    }
    
    // MARK: - Currency
    
    public func getSelectedCurrency() throws -> Currency {
        try walletProvider.activeWallet.currency
    }
    
    public func getAvailableCurrencies() -> [Currency] {
        Currency.allCases
    }
    
    public func setCurrency(_ currency: Currency) throws {
        let wallet = try walletProvider.activeWallet.setCurrency(currency)
        try keeperInfoService.updateKeeperInfo(with: wallet)
        notifyObservers()
    }
    
    // MARK: - Biometry
    
    public func getIsBiometryEnabled() -> Bool {
        securityController.getIsBiometryEnabled()
    }
    
    public func setIsBiometryEnabled(_ isBiometryEnabled: Bool) throws {
        try securityController.setIsBiometryEnabled(isBiometryEnabled)
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
