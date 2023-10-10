//
//  SecuritySettings+Update.swift
//
//
//  Created by Grigory on 10.10.23..
//

import Foundation

extension SecuritySettings {
    func setIsBiometryEnabled(_ isBiometryEnabled: Bool) -> SecuritySettings {
        return .init(isBiometryEnabled: isBiometryEnabled)
    }
}
