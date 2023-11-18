//
//  KeeperInfo.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation

/// Represents the entire state of the application install
public struct KeeperInfo: Codable {
    /// Keeper contains multiple wallets
    let wallets: [Wallet]
    
    /// Currently selected wallet
    let currentWallet: WalletIdentity
    
    /// Common pin/faceid settings
    let securitySettings: SecuritySettings
    
    ///
    let assetsPolicy: AssetsPolicy
    let appCollection: AppCollection
}
