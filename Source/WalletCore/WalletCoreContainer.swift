//
//  WalletCoreContainer.swift
//  
//
//  Created by Grigory on 28.6.23..
//

import Foundation
import TonSwift

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
    
    public func sendController(transferModel: TransferModel,
                               recipient: Recipient,
                               comment: String?) -> SendController {
        switch transferModel {
        case .token(let tokenTransferModel):
            walletCoreAssembly.tokenSendController(tokenTransferModel: tokenTransferModel,
                                                   recipient: recipient,
                                                   comment: comment,
                                                   walletProvider: keeperController())
        case .nft(let collectible):
            walletCoreAssembly.nftSendController(collectible,
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
    
    public func chartController() -> ChartController {
        walletCoreAssembly.chartController()
    }
    
    public func collectibleDetailsController(collectibleAddress: Address) -> CollectibleDetailsController {
        walletCoreAssembly.collectibleDetailsController(collectibleAddress: collectibleAddress)
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
