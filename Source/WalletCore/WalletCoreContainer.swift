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
    
    public func sendRecipientController() -> SendRecipientController {
        walletCoreAssembly.sendRecipientController()
    }
    
    public func receiveController() -> ReceiveController {
        walletCoreAssembly.receiveController(walletProvider: keeperController())
    }
    
    public func tokenDetailsTonController() -> TokenDetailsController {
        walletCoreAssembly.tokenDetailsTonController(walletProvider: keeperController())
    }
    
    public func tokenDetailsTokenController(tokenInfo: TokenInfo) -> TokenDetailsController {
        walletCoreAssembly.tokenDetailsTokenController(tokenInfo: tokenInfo,
                                                       walletProvider: keeperController())
    }
    
    public func activityListController() -> ActivityListController {
        walletCoreAssembly.activityListController(walletProvider: keeperController())
    }
    
    public func activityListTonEventsController() -> ActivityListController {
        walletCoreAssembly.activityListTonEventsController(walletProvider: keeperController())
    }
    
    public func activityListTokenEventsController(tokenInfo: TokenInfo) -> ActivityListController {
        walletCoreAssembly.activityListTokenEventsController(walletProvider: keeperController(), tokenInfo: tokenInfo)
    }
    
    public func chartController() -> ChartController {
        walletCoreAssembly.chartController()
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
