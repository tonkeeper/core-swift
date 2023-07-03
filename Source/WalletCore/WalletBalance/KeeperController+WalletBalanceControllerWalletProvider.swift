//
//  KeeperController+WalletBalanceControllerWalletProvider.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation

extension KeeperController: WalletBalanceControllerWalletProvider {
    var wallet: Wallet {
        get throws {
            try activeWallet
        }
    }
}
