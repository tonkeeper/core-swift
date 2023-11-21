//
//  SettingsAssembly.swift
//
//
//  Created by Grigory on 3.10.23..
//

import Foundation

final class SettingsAssembly {
    
    private var _settingsController: SettingsController?
    private let configurationAssembly: ConfigurationAssembly
    private let coreAssembly: CoreAssembly
    
    init(configurationAssembly: ConfigurationAssembly,
         coreAssembly: CoreAssembly) {
        self.configurationAssembly = configurationAssembly
        self.coreAssembly = coreAssembly
    }
    
    func settingsController() -> SettingsController {
        guard let settingsController = _settingsController else {
            let settingsController = SettingsControllerImplementation(
                walletProvider: coreAssembly.walletProvider,
                securityController: coreAssembly.securityController,
                configurationController: configurationAssembly.configurationController(),
                keeperInfoService: coreAssembly.keeperInfoService
            )
            self._settingsController = settingsController
            return settingsController
        }
        return settingsController
    }
    
    func logoutController(cacheURL: URL,
                          keychainGroup: String) -> LogoutController {
        LogoutController(
            cacheURL: cacheURL,
            keychainGroup: keychainGroup,
            keeperInfoService: coreAssembly.keeperInfoService,
            fileManager: coreAssembly.fileManager,
            keychainVault: coreAssembly.keychainVault
        )
    }
}
