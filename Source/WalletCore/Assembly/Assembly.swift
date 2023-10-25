//
//  Assembly.swift
//  
//
//  Created by Grigory Serebryanyy on 24.10.2023.
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

public final class Assembly {
    private let dependencies: Dependencies
    
    private let coreAssembly = CoreAssembly()
    private let formattersAssembly = FormattersAssembly()
    private let validatorsAssembly = ValidatorsAssembly()
    private let deeplinkAssembly = DeeplinkAssembly()
    private lazy var apiAssembly = APIAssembly(
        coreAssembly: self.coreAssembly,
        configurationAssembly: self.configurationAssembly
    )
    private let legacyApiAssembly = LegacyAPIAssembly()
    private lazy var servicesAssembly = ServicesAssembly(
        coreAssembly: coreAssembly,
        apiAssembly: apiAssembly,
        legacyApiAssembly: legacyApiAssembly,
        cacheURL: dependencies.cacheURL,
        sharedCacheURL: dependencies.sharedCacheURL
    )
    private lazy var keeperAssembly = KeeperAssembly(
        coreAssembly: coreAssembly,
        servicesAssembly: servicesAssembly,
        keychainGroup: dependencies.sharedKeychainGroup
    )
    private let receiveAssembly = ReceiveAssembly()
    private lazy var sendAssembly = SendAssembly(
        coreAssembly: coreAssembly,
        apiAssembly: apiAssembly,
        servicesAssembly: servicesAssembly,
        keeperAssembly: keeperAssembly,
        balanceAssembly: walletBalanceAssembly,
        formattersAssembly: formattersAssembly,
        cacheURL: dependencies.cacheURL
    )
    private lazy var walletBalanceAssembly = WalletBalanceAssembly(
        servicesAssembly: servicesAssembly,
        formattersAssembly: formattersAssembly,
        keeperAssembly: keeperAssembly
    )
    private lazy var collectibleAssembly = CollectibleAssembly(
        servicesAssembly: servicesAssembly,
        formattersAssembly: formattersAssembly
    )
    private lazy var activityAssembly = ActivityAssembly(
        coreAssembly: coreAssembly,
        apiAssembly: apiAssembly,
        servicesAssembly: servicesAssembly,
        formattersAssembly: formattersAssembly,
        keeperAssembly: keeperAssembly,
        cacheURL: dependencies.cacheURL
    )
    private lazy var widgetAssembly = WidgetAssembly(
        formattersAssembly: formattersAssembly,
        walletBalanceAssembly: walletBalanceAssembly,
        keeperAssembly: keeperAssembly,
        servicesAssembly: servicesAssembly
    )
    private lazy var settingsAssembly = SettingsAssembly(configurationAssembly: configurationAssembly)
    private lazy var configurationAssembly = ConfigurationAssembly(
        coreAssembly: coreAssembly,
        legacyAPIAssembly: legacyApiAssembly,
        cacheURL: dependencies.cacheURL
    )
    private lazy var tokenDetailsAssembly = TokenDetailsAssembly(
        formattersAssembly: formattersAssembly,
        servicesAssembly: servicesAssembly,
        keeperAssembly: keeperAssembly,
        apiAssembly: apiAssembly
    )
    private lazy var tonConnectAssembly = TonConnectAssembly()
    
    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

public extension Assembly {
    var configurationController: ConfigurationController {
        configurationAssembly.configurationController()
    }
    
    var keeperController: KeeperController {
        keeperAssembly.keeperController
    }
    
    var passcodeController: PasscodeController {
        PasscodeController(passcodeVault: coreAssembly.keychainPasscodeVault)
    }
    
    var walletBalanceController: WalletBalanceController {
        walletBalanceAssembly.walletBalanceController
    }
    
    var sendInputController: SendInputController {
        sendAssembly.sendInputController()
    }
    
    func sendController(transferModel: TransferModel,
                        recipient: Recipient,
                        comment: String?) -> SendController {
        switch transferModel {
        case .token(let tokenTransferModel):
            return tokenSendController(
                tokenTransferModel: tokenTransferModel,
                recipient: recipient,
                comment: comment)
        case .nft(let nftAddress):
            return nftSendController(
                nftAddress: nftAddress,
                recipient: recipient,
                comment: comment)
        }
    }
    
    func tokenSendController(tokenTransferModel: TokenTransferModel,
                             recipient: Recipient,
                             comment: String?) -> SendController {
        sendAssembly.tokenSendController(
            tokenTransferModel: tokenTransferModel,
            recipient: recipient,
            comment: comment,
            walletProvider: keeperAssembly.keeperController,
            keychainGroup: dependencies.sharedKeychainGroup)
    }
    
    func nftSendController(nftAddress: Address,
                             recipient: Recipient,
                             comment: String?) -> SendController {
        sendAssembly.nftSendController(
            nftAddress: nftAddress,
            recipient: recipient,
            comment: comment,
            walletProvider: keeperAssembly.keeperController,
            keychainGroup: dependencies.sharedKeychainGroup)
    }
    
    func sendRecipientController() -> SendRecipientController {
        sendAssembly.sendRecipientController()
    }
    
    func receiveController() -> ReceiveController {
        receiveAssembly.receiveController(walletProvider: keeperAssembly.keeperController)
    }
    
    func tokenDetailsTonController() -> TokenDetailsController {
        tokenDetailsAssembly.tokenDetailsTonController()
    }
    
    func tokenDetailsTokenController(tokenInfo: TokenInfo) -> TokenDetailsController {
        tokenDetailsAssembly.tokenDetailsTokenController(tokenInfo)
    }
    
    func activityListController() -> ActivityListController {
        activityAssembly.activityListController
    }
    
    func activityListTonEventsController() -> ActivityListController {
        activityAssembly.activityListTonEventsController
    }
    
    func activityListTokenEventsController(tokenInfo: TokenInfo) -> ActivityListController {
        activityAssembly.activityListTokenEventsController(tokenInfo: tokenInfo)
    }
    
    func activityController() -> ActivityController {
        activityAssembly.activityController()
    }
    
    func chartController() -> ChartController {
        tokenDetailsAssembly.chartController()
    }
    
    func collectibleDetailsController(collectibleAddress: Address) -> CollectibleDetailsController {
        collectibleAssembly.collectibleDetailsController(
            collectibleAddress: collectibleAddress,
            walletProvider: keeperAssembly.keeperController,
            contractBuilder: WalletContractBuilder())
    }
    
    func balanceWidgetController() -> BalanceWidgetController {
        widgetAssembly.balanceWidgetController()
    }
    
    func settingsController() -> SettingsController {
        settingsAssembly.settingsController(keeperController: keeperAssembly.keeperController)
    }
    
    func logoutController() -> LogoutController {
        settingsAssembly.logoutController(
            cacheURL: dependencies.cacheURL,
            keychainGroup: dependencies.sharedKeychainGroup,
            keeperInfoService: servicesAssembly.keeperInfoService,
            fileManager: coreAssembly.fileManager,
            keychainManager: coreAssembly.keychainManager
        )
    }
    
    func tonConnectDeeplinkProcessor() -> TonConnectDeeplinkProcessor {
        tonConnectAssembly.tonConnectDeeplinkProcessor()
    }
    
    func tonConnectController(parameters: TCParameters,
                              manifest: TonConnectManifest) -> TonConnectController {
        tonConnectAssembly.tonConnectController(
            parameters: parameters,
            manifest: manifest
        )
    }
    
    func fiatMethodsController() -> FiatMethodsController {
        FiatMethodsController(
            fiatMethodsService: servicesAssembly.fiatMethodsService,
            walletProvider: keeperAssembly.keeperController,
            configurationController: configurationAssembly.configurationController()
        )
    }
    
    func deeplinkParser(handlers: [DeeplinkHandler]) -> DeeplinkParser {
        deeplinkAssembly.deeplinkParser(handlers: handlers)
    }
    
    var tonDeeplinkHandler: DeeplinkHandler {
        TonDeeplinkHandler()
    }
    
    var tonConnectDeeplinkHandler: DeeplinkHandler {
        TonConnectDeeplinkHandler()
    }
    
    func deeplinkGenerator() -> DeeplinkGenerator {
        deeplinkAssembly.deeplinkGenerator
    }
    
    func addressValidator() -> AddressValidator {
        validatorsAssembly.addressValidator
    }
}
