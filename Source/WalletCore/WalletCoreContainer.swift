//
//  WalletCoreContainer.swift
//  
//
//  Created by Grigory on 28.6.23..
//

import Foundation

public struct WalletCoreContainer {
    
    let walletCoreAssembly = WalletCoreAssembly()
    
    public init() {}
    
    public func keeperController(url: URL) -> KeeperController {
        walletCoreAssembly.keeperController(url: url)
    }
    
    public func passcodeController() -> PasscodeController {
        walletCoreAssembly.passcodeController()
    }
}
