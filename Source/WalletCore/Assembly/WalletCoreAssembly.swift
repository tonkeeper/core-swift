//
//  WalletCoreAssembly.swift
//  
//
//  Created by Grigory on 28.6.23..
//

import Foundation
import TonAPI

final class WalletCoreAssembly {
    
    private let formattersAssembly = FormattersAssembly()
    private let coreAssembly = CoreAssembly()
    private let deeplinkAssembly = DeeplinkAssembly()
    private let validatorsAssembly = ValidatorsAssembly()
    private let tokenDetailsAssembly = TokenDetailsAssembly()
    private lazy var ratesAssembly = RatesAssembly(coreAssembly: coreAssembly)
    private lazy var apiAssembly = APIAssembly(coreAssembly: coreAssembly)
    private lazy var walletBalanceAssembly = WalletBalanceAssembly(coreAssembly: coreAssembly,
                                                                   formattersAssembly: formattersAssembly)
    private lazy var sendAssembly = SendAssembly(formattersAssembly: formattersAssembly,
                                                 ratesAssembly: ratesAssembly,
                                                 balanceAssembly: walletBalanceAssembly,
                                                 coreAssembly: coreAssembly)
    private lazy var keeperInfoAssembly = KeeperInfoAssembly(coreAssembly: coreAssembly)
    private lazy var confifurationAssembly = ConfigurationAssembly(coreAssembly: coreAssembly)
    
    private lazy var tonAPI: API = apiAssembly.tonAPI(requestInterceptors: [accessTokenProvider])
    private lazy var configurationAPI: API = apiAssembly.configurationAPI()
    
    lazy var keeperController: KeeperController = keeperInfoAssembly.keeperController(cacheURL: cacheURL)
    
    private let cacheURL: URL
    init(cacheURL: URL) {
        self.cacheURL = cacheURL
    }
    
    func passcodeController() -> PasscodeController {
        PasscodeController(passcodeVault: coreAssembly.keychainPasscodeVault)
    }
    
    func walletBalanceController() -> WalletBalanceController {
        WalletBalanceController(
            balanceService: walletBalanceAssembly.walletBalanceService(api: tonAPI, cacheURL: cacheURL),
            ratesService: ratesAssembly.ratesService(api: tonAPI, cacheURL: cacheURL),
            walletProvider: keeperController,
            walletBalanceMapper: walletBalanceAssembly.walletBalanceMapper())
    }
    
    func sendInputController(walletProvider: WalletProvider) -> SendInputController {
        sendAssembly.sendInputController(api: tonAPI, cacheURL: cacheURL, walletProvider: walletProvider)
    }
    
    func sendController(walletProvider: WalletProvider) -> SendController {
        sendAssembly.sendController(
            api: tonAPI,
            cacheURL: cacheURL,
            walletProvider: walletProvider
        )
    }
    
    func tokenDetailsTonController() -> TokenDetailsController {
        tokenDetailsAssembly.tokenDetailsTonController()
    }
    
    func tokenDetailsTokenController(tokenInfo: TokenInfo) -> TokenDetailsController {
        tokenDetailsAssembly.tokenDetailsTokenController(tokenInfo)
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
        AccessTokenProvider(configurationController: confifurationAssembly.configurationController(api: configurationAPI, cacheURL: cacheURL))
    }
}
