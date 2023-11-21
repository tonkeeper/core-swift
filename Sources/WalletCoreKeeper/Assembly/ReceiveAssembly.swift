//
//  ReceiveAssembly.swift
//  
//
//  Created by Grigory on 18.7.23..
//

import Foundation

final class ReceiveAssembly {
    private let coreAssembly: CoreAssembly
    
    init(coreAssembly: CoreAssembly) {
        self.coreAssembly = coreAssembly
    }
    
    func receiveController() -> ReceiveController {
        ReceiveController(walletProvider: coreAssembly.walletProvider)
    }
}
