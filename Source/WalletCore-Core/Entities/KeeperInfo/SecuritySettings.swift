//
//  SecuritySettings.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation

/// Shared security settings for all wallets in the app
struct SecuritySettings {
    let isBiometryEnabled: Bool
    // passcode
    // lock screen
    // hidden balances
}

extension SecuritySettings: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isBiometryEnabled = (try? container.decode(Bool.self, forKey: .isBiometryEnabled)) ?? false
    }
}
