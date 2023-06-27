//
//  KeeperInfo+Update.swift
//  
//
//  Created by Grigory on 27.6.23..
//

import Foundation

extension KeeperInfo {
    func addWallet(_ wallet: Wallet) -> KeeperInfo {
        var updatedWallets = self.wallets
        updatedWallets.append(wallet)
        return .init(wallets: updatedWallets,
                     currentWallet: self.currentWallet,
                     securitySettings: self.securitySettings,
                     assetsPolicy: self.assetsPolicy,
                     appCollection: self.appCollection)
    }
    
    func makeWalletActive(_ wallet: Wallet) -> KeeperInfo {
        return .init(wallets: self.wallets,
                     currentWallet: wallet,
                     securitySettings: self.securitySettings,
                     assetsPolicy: self.assetsPolicy,
                     appCollection: self.appCollection)
    }
}
