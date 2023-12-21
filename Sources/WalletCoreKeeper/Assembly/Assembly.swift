//
//  Assembly.swift
//  
//
//  Created by Grigory Serebryanyy on 24.10.2023.
//

import Foundation
import TonSwift
import WalletCoreCore

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

typealias CoreAssembly = WalletCoreCore.Assembly

public final class Assembly {
    private let dependencies: Dependencies
    
    private let coreAssembly: CoreAssembly
    private let formattersAssembly = FormattersAssembly()
    private let validatorsAssembly = ValidatorsAssembly()
    private let deeplinkAssembly = DeeplinkAssembly()
    private lazy var apiAssembly = APIAssembly(
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
    private lazy var storesAssembly = StoresAssembly(
        servicesAssembly: servicesAssembly,
        coreAssembly: coreAssembly
    )
    private lazy var receiveAssembly = ReceiveAssembly(coreAssembly: coreAssembly)
    private lazy var sendAssembly = SendAssembly(
        coreAssembly: coreAssembly,
        apiAssembly: apiAssembly,
        servicesAssembly: servicesAssembly,
        balanceAssembly: walletBalanceAssembly,
        formattersAssembly: formattersAssembly,
        cacheURL: dependencies.cacheURL,
        keychainGroup: dependencies.sharedKeychainGroup
    )
    private lazy var walletBalanceAssembly = WalletBalanceAssembly(
        servicesAssembly: servicesAssembly,
        formattersAssembly: formattersAssembly,
        coreAssembly: coreAssembly,
        storesAssembly: storesAssembly
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
        storesAssembly: storesAssembly,
        cacheURL: dependencies.cacheURL
    )
    private lazy var widgetAssembly = WidgetAssembly(
        formattersAssembly: formattersAssembly,
        walletBalanceAssembly: walletBalanceAssembly,
        servicesAssembly: servicesAssembly,
        coreAssembly: coreAssembly
    )
    private lazy var settingsAssembly = SettingsAssembly(
        configurationAssembly: configurationAssembly, 
        coreAssembly: coreAssembly
    )
    private lazy var configurationAssembly = ConfigurationAssembly(
        coreAssembly: coreAssembly,
        legacyAPIAssembly: legacyApiAssembly,
        cacheURL: dependencies.cacheURL
    )
    private lazy var tokenDetailsAssembly = TokenDetailsAssembly(
        coreAssembly: coreAssembly,
        formattersAssembly: formattersAssembly,
        servicesAssembly: servicesAssembly,
        apiAssembly: apiAssembly
    )
    private lazy var tonConnectAssembly = TonConnectAssembly(
        coreAssembly: coreAssembly,
        apiAssembly: apiAssembly,
        sendAssembly: sendAssembly,
        servicesAssembly: servicesAssembly,
        formattersAssembly: formattersAssembly,
        cacheURL: dependencies.cacheURL,
        keychainGroup: dependencies.sharedKeychainGroup
    )
    
    private weak var _transactionsEventsDaemon: TransactionsEventDaemon?
    
    public var transactionsEventsDaemon: TransactionsEventDaemon {
        if let _transactionsEventsDaemon = _transactionsEventsDaemon {
            return _transactionsEventsDaemon
        } else {
            let transactionsEventsDaemon = TransactionsEventDaemonImplementation(streamingAPI: apiAssembly.streamingTonAPIClient())
            self._transactionsEventsDaemon = transactionsEventsDaemon
            return transactionsEventsDaemon
        }
    }
    
    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
        self.coreAssembly = CoreAssembly(
            dependencies:
                    .init(cacheURL: dependencies.cacheURL, sharedCacheURL: 
                            dependencies.sharedCacheURL,
                          sharedKeychainGroup: dependencies.sharedKeychainGroup)
        )
    }
}

public extension Assembly {
    var configurationController: ConfigurationController {
        configurationAssembly.configurationController()
    }
    
    var walletsController: WalletsController {
        coreAssembly.walletsController
    }
    
    var walletsProvider: WalletProvider {
        coreAssembly.walletProvider
    }
    
    var balanceController: BalanceController {
        return walletBalanceAssembly.balanceController()
    }

    var sendInputController: SendInputController {
        sendAssembly.sendInputController()
    }
    
    var passcodeController: PasscodeController {
        coreAssembly.passcodeController
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
            keychainGroup: dependencies.sharedKeychainGroup)
    }
    
    func nftSendController(nftAddress: Address,
                             recipient: Recipient,
                             comment: String?) -> SendController {
        sendAssembly.nftSendController(
            nftAddress: nftAddress,
            recipient: recipient,
            comment: comment,
            keychainGroup: dependencies.sharedKeychainGroup)
    }
    
    func sendRecipientController() -> SendRecipientController {
        sendAssembly.sendRecipientController()
    }
    
    func receiveController() -> ReceiveController {
        receiveAssembly.receiveController()
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
    
    func activityEventDetailsController(action: ActivityEventAction) -> ActivityEventDetailsController {
        activityAssembly.activityEventDetailsController(action: action)
    }
    
    func chartController() -> ChartController {
        tokenDetailsAssembly.chartController()
    }
    
    func collectibleDetailsController(collectibleAddress: Address) -> CollectibleDetailsController {
        collectibleAssembly.collectibleDetailsController(
            collectibleAddress: collectibleAddress,
            walletProvider: coreAssembly.walletProvider,
            contractBuilder: WalletContractBuilder())
    }
    
    func balanceWidgetController() -> BalanceWidgetController {
        widgetAssembly.balanceWidgetController()
    }
    
    func settingsController() -> SettingsController {
        settingsAssembly.settingsController()
    }
    
    func logoutController() -> LogoutController {
        settingsAssembly.logoutController(
            cacheURL: dependencies.cacheURL,
            keychainGroup: dependencies.sharedKeychainGroup
        )
    }
    
    func tonConnectDeeplinkProcessor() -> TonConnectDeeplinkProcessor {
        tonConnectAssembly.tonConnectDeeplinkProcessor()
    }
    
    func tonConnectController(parameters: TonConnectParameters,
                              manifest: TonConnectManifest) -> TonConnectController {
        tonConnectAssembly.tonConnectController(
            parameters: parameters,
            manifest: manifest
        )
    }
    
    func tonConnectConfirmationController() -> TonConnectConfirmationController {
        tonConnectAssembly.tonConnectConfirmationController()
    }
    
    func tonConnectEventsDaemon() -> TonConnectEventsDaemon {
        tonConnectAssembly.tonConnectEventsDaemon
    }
    
    func fiatMethodsController() -> FiatMethodsController {
        FiatMethodsController(
            fiatMethodsService: servicesAssembly.fiatMethodsService,
            walletProvider: coreAssembly.walletProvider,
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
