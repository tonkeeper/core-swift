//
//  SettingsAssembly.swift
//
//
//  Created by Grigory on 3.10.23..
//

import Foundation

final class SettingsAssembly {
    
    private var settingsController: SettingsController?
    
    func settingsController(keeperController: KeeperController) -> SettingsController {
        guard let settingsController = settingsController else {
            let settingsController = SettingsController(keeperController: keeperController)
            self.settingsController = settingsController
            return settingsController
        }
        return settingsController
    }
}
