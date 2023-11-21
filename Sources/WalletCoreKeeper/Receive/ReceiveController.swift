//
//  ReceiveController.swift
//  
//
//  Created by Grigory on 18.7.23..
//

import Foundation
import WalletCoreCore

public final class ReceiveController {
    
    private let walletProvider: WalletProvider
    
    init(walletProvider: WalletProvider) {
        self.walletProvider = walletProvider
    }
    
    public func getWalletAddress() throws -> String {
        let address = try walletProvider.activeWallet.address
        return address.toString(bounceable: false)
    }
}
