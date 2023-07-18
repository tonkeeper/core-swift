//
//  ReceiveController.swift
//  
//
//  Created by Grigory on 18.7.23..
//

import Foundation

public final class ReceiveController {
    
    private let walletProvider: WalletProvider
    private let contractBuilder: WalletContractBuilder
    
    init(walletProvider: WalletProvider, contractBuilder: WalletContractBuilder) {
        self.walletProvider = walletProvider
        self.contractBuilder = contractBuilder
    }
    
    public func getWalletAddress() throws -> String {
        let wallet = try walletProvider.activeWallet
        let publicKey = try wallet.publicKey
        let contract = try contractBuilder.walletContract(
            with: publicKey,
            contractVersion: wallet.contractVersion
        )
        let address = try contract.address()
        return address.toString()
    }
}
