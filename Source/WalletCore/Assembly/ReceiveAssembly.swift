//
//  ReceiveAssembly.swift
//  
//
//  Created by Grigory on 18.7.23..
//

import Foundation

final class ReceiveAssembly {
    func receiveController(walletProvider: WalletProvider) -> ReceiveController {
        ReceiveController(walletProvider: walletProvider,
                          contractBuilder: WalletContractBuilder())
    }
}
