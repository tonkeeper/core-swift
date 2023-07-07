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
    
    public func sendInputController() -> SendInputController {
        walletCoreAssembly.sendInputController(walletProvider: keeperController())
    }
    
    public func sendController() -> SendController {
        walletCoreAssembly.sendController(walletProvider: keeperController())
    }
    
    public func deeplinkParser() -> DeeplinkParser {
        walletCoreAssembly.deeplinkParser()
    }
    
    public func deeplinkGenerator() -> DeeplinkGenerator {
        walletCoreAssembly.deeplinkGenerator()
    }
    
    public func addressValidator() -> AddressValidator {
        walletCoreAssembly.addressValidator()
    }
}
