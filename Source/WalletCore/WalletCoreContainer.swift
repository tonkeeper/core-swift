//
//  WalletCoreContainer.swift
//  
//
//  Created by Grigory on 28.6.23..
//

import Foundation
import TonSwift

public struct Dependencies {
    public let cacheURL: URL
    public let sharedCacheURL: URL
    public let sharedKeychainGroup: String
    
    public init(cacheURL: URL,
                sharedCacheURL: URL,
                sharedKeychainGroup: String) {
        self.cacheURL = cacheURL
        self.sharedCacheURL = sharedCacheURL
        self.sharedKeychainGroup = sharedKeychainGroup
    }
}

public final class WalletCoreContainer {
    
    let walletCoreAssembly: WalletCoreAssembly
    
    public init(dependencies: Dependencies) {
        walletCoreAssembly = WalletCoreAssembly(dependencies: dependencies)
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
    
    public func sendController(transferModel: TransferModel,
                               recipient: Recipient,
                               comment: String?) -> SendController {
        switch transferModel {
        case .token(let tokenTransferModel):
            return walletCoreAssembly.tokenSendController(tokenTransferModel: tokenTransferModel,
                                                   recipient: recipient,
                                                   comment: comment,
                                                   walletProvider: keeperController())
        case .nft(let nftAddress):
            return walletCoreAssembly.nftSendController(nftAddress: nftAddress,
                                                 recipient: recipient,
                                                 comment: comment,
                                                 walletProvider: keeperController())
        }
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
    
    public func activityController() -> ActivityController {
        walletCoreAssembly
            .activityController()
    }
    
    public func chartController() -> ChartController {
        walletCoreAssembly.chartController()
    }
    
    public func collectibleDetailsController(collectibleAddress: Address) -> CollectibleDetailsController {
        walletCoreAssembly.collectibleDetailsController(collectibleAddress: collectibleAddress)
    }
    
    public func balanceWidgetController() -> BalanceWidgetController {
        walletCoreAssembly.balanceWidgetController()
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
