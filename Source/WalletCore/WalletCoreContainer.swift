//
//  WalletCoreContainer.swift
//  
//
//  Created by Grigory on 28.6.23..
//

import Foundation

public final class WalletCoreContainer {
    
    private let cacheURL: URL
    
    lazy var walletCoreAssembly = WalletCoreAssembly(cacheURL: cacheURL)
    
    public init(cacheURL: URL) {
        self.cacheURL = cacheURL
    }
    
    public func keeperController() -> KeeperController {
        walletCoreAssembly.keeperController
    }
    
    public func passcodeController() -> PasscodeController {
        walletCoreAssembly.passcodeController()
    }
    
    public func walletBalanceController() -> WalletBalanceController {
        walletCoreAssembly.walletBalanceController()
    }
}
