//
//  SecurityController.swift
//
//
//  Created by Grigory Serebryanyy on 20.11.2023.
//

import Foundation

public final class SecurityController {
    private let keeperInfoService: KeeperInfoService
    
    init(keeperInfoService: KeeperInfoService) {
        self.keeperInfoService = keeperInfoService
    }
    
    public func getIsBiometryEnabled() -> Bool {
        do {
            return try keeperInfoService.getKeeperInfo().securitySettings.isBiometryEnabled
        } catch {
            return false
        }
    }
    
    public func setIsBiometryEnabled(_ isBiometryEnabled: Bool) throws {
        let keeperInfo = try keeperInfoService.getKeeperInfo()
        let securitySettings = keeperInfo.securitySettings.setIsBiometryEnabled(isBiometryEnabled)
        try keeperInfoService.saveKeeperInfo(keeperInfo.updateSecuritySettings(securitySettings))
    }
}
