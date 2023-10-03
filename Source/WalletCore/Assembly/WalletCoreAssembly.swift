//
//  WalletCoreAssembly.swift
//  
//
//  Created by Grigory on 28.6.23..
//

import Foundation
import TonAPI
import TonSwift

final class WalletCoreAssembly {
    
    private let formattersAssembly = FormattersAssembly()
    private let coreAssembly = CoreAssembly()
    private let deeplinkAssembly = DeeplinkAssembly()
    private let validatorsAssembly = ValidatorsAssembly()
    private lazy var tokenDetailsAssembly = TokenDetailsAssembly(formattersAssembly: formattersAssembly)
    private lazy var ratesAssembly = RatesAssembly(coreAssembly: coreAssembly)
    private lazy var apiAssembly = APIAssembly(coreAssembly: coreAssembly)
    private lazy var walletBalanceAssembly = WalletBalanceAssembly(coreAssembly: coreAssembly,
                                                                   servicesAssembly: servicesAssembly,
                                                                   formattersAssembly: formattersAssembly)
    private lazy var sendAssembly = SendAssembly(formattersAssembly: formattersAssembly,
                                                 ratesAssembly: ratesAssembly,
                                                 balanceAssembly: walletBalanceAssembly,
                                                 servicesAssembly: servicesAssembly,
                                                 coreAssembly: coreAssembly)
    private lazy var receiveAssembly = ReceiveAssembly()
    private lazy var keeperInfoAssembly = KeeperInfoAssembly(coreAssembly: coreAssembly)
    private lazy var confifurationAssembly = ConfigurationAssembly(coreAssembly: coreAssembly)
    
    private lazy var tonAPI: API = apiAssembly.tonAPI(requestInterceptors: [accessTokenProvider])
    private lazy var configurationAPI: API = apiAssembly.configurationAPI()
    private lazy var streamingAPI: StreamingAPI = apiAssembly.streamingAPI(requestInterceptors: [accessTokenProvider])
    
    lazy var keeperController: KeeperController = keeperInfoAssembly
        .keeperController(cacheURL: dependencies.sharedCacheURL,
                          keychainGroup: dependencies.sharedKeychainGroup)
    
    private lazy var servicesAssembly = ServicesAssembly(tonAPI: tonAPI,
                                                         tonkeeperAPI: configurationAPI,
                                                         streamingAPI: streamingAPI,
                                                         coreAssembly: coreAssembly,
                                                         cacheURL: dependencies.cacheURL)
    private lazy var collectibleAssembly = CollectibleAssembly(servicesAssembly: servicesAssembly,
                                                               formattersAssembly: formattersAssembly)
    private lazy var activityAssembly = ActivityAssembly(servicesAssembly: servicesAssembly,
                                                         coreAssembly: coreAssembly,
                                                         formattersAssembly: formattersAssembly)
    
    private lazy var widgetAssembly = WidgetAssembly(formattersAssembly: formattersAssembly,
                                                     walletBalanceAssembly: walletBalanceAssembly,
                                                     ratesAssembly: ratesAssembly)
    
    private lazy var settingsAssembly = SettingsAssembly()
    
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    func passcodeController() -> PasscodeController {
        PasscodeController(passcodeVault: coreAssembly.keychainPasscodeVault)
    }
    
    func walletBalanceController() -> WalletBalanceController {
        WalletBalanceController(
            balanceService: walletBalanceAssembly.walletBalanceService(api: tonAPI, cacheURL: dependencies.cacheURL),
            ratesService: ratesAssembly.ratesService(api: tonAPI, cacheURL: dependencies.cacheURL),
            walletProvider: keeperController,
            walletBalanceMapper: walletBalanceAssembly.walletBalanceMapper(),
            transactionsUpdatePublishService: servicesAssembly.transactionsUpdateService)
    }
    
    func sendInputController(walletProvider: WalletProvider) -> SendInputController {
        sendAssembly.sendInputController(api: tonAPI, cacheURL: dependencies.cacheURL, walletProvider: walletProvider)
    }
    
    func tokenSendController(tokenTransferModel: TokenTransferModel,
                             recipient: Recipient,
                             comment: String?,
                             walletProvider: WalletProvider) -> SendController {
        sendAssembly.tokenSendController(
            api: tonAPI,
            cacheURL: dependencies.cacheURL,
            tokenTransferModel: tokenTransferModel,
            recipient: recipient,
            comment: comment,
            walletProvider: walletProvider,
            keychainGroup: dependencies.sharedKeychainGroup
        )
    }
    
    func nftSendController(nftAddress: Address,
                           recipient: Recipient,
                           comment: String?,
                           walletProvider: WalletProvider) -> SendController {
        sendAssembly.nftSendController(
            api: tonAPI,
            cacheURL: dependencies.cacheURL,
            nftAddress: nftAddress,
            recipient: recipient,
            comment: comment,
            walletProvider: walletProvider,
            keychainGroup: dependencies.sharedKeychainGroup
        )
    }
    
    func sendRecipientController() -> SendRecipientController {
        sendAssembly.sendRecipientController(api: tonAPI)
    }
    
    func receiveController(walletProvider: WalletProvider) -> ReceiveController {
        receiveAssembly.receiveController(walletProvider: walletProvider)
    }
    
    func tokenDetailsTonController(walletProvider: WalletProvider) -> TokenDetailsController {
        tokenDetailsAssembly.tokenDetailsTonController(
            ratesService: ratesAssembly.ratesService(api: tonAPI, cacheURL: dependencies.cacheURL),
            balaceService: walletBalanceAssembly.walletBalanceService(api: tonAPI, cacheURL: dependencies.cacheURL),
            walletProvider: walletProvider
        )
    }
    
    func tokenDetailsTokenController(tokenInfo: TokenInfo,
                                     walletProvider: WalletProvider) -> TokenDetailsController {
        tokenDetailsAssembly.tokenDetailsTokenController(
            tokenInfo,
            ratesService: ratesAssembly.ratesService(api: tonAPI, cacheURL: dependencies.cacheURL),
            balaceService: walletBalanceAssembly.walletBalanceService(api: tonAPI, cacheURL: dependencies.cacheURL),
            walletProvider: walletProvider
        )
    }
    
    func activityListController(walletProvider: WalletProvider) -> ActivityListController {
        activityAssembly
        .activityListController(api: tonAPI,
                                walletProvider: walletProvider,
                                cacheURL: dependencies.cacheURL
        )
    }
    
    func activityListTonEventsController(walletProvider: WalletProvider) -> ActivityListController {
        activityAssembly
        .activityListTonEventsController(
            api: tonAPI,
            walletProvider: walletProvider,
            cacheURL: dependencies.cacheURL
        )
    }
    
    func activityListTokenEventsController(walletProvider: WalletProvider, tokenInfo: TokenInfo) -> ActivityListController {
        activityAssembly
        .activityListTokenEventsController(
            api: tonAPI,
            walletProvider: walletProvider,
            cacheURL: dependencies.cacheURL,
            tokenInfo: tokenInfo
        )
    }
    
    func activityController() -> ActivityController {
        activityAssembly
            .activityController()
    }
    
    func chartController() -> ChartController {
        tokenDetailsAssembly.chartController(api: tonAPI)
    }
    
    func collectibleDetailsController(collectibleAddress: Address) -> CollectibleDetailsController {
        collectibleAssembly.collectibleDetailsController(collectibleAddress: collectibleAddress,
                                                         walletProvider: keeperController,
                                                         contractBuilder: WalletContractBuilder())
    }
    
    func balanceWidgetController() -> BalanceWidgetController {
        widgetAssembly.balanceWidgetController(
            walletProvider: keeperController,
            api: tonAPI,
            cacheURL: dependencies.cacheURL)
    }
    
    func settingsController() -> SettingsController {
        settingsAssembly.settingsController(keeperController: keeperController)
    }
    
    func deeplinkParser() -> DeeplinkParser {
        deeplinkAssembly.deeplinkParser
    }
    
    func deeplinkGenerator() -> DeeplinkGenerator {
        deeplinkAssembly.deeplinkGenerator
    }
    
    func addressValidator() -> AddressValidator {
        validatorsAssembly.addressValidator
    }
}

private extension WalletCoreAssembly {
    var accessTokenProvider: AccessTokenProvider {
        AccessTokenProvider(configurationController: confifurationAssembly.configurationController(api: configurationAPI, cacheURL: dependencies.cacheURL))
    }
}
