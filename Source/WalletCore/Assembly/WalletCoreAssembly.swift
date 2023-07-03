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
    private lazy var ratesAssembly = RatesAssembly(coreAssembly: coreAssembly)
    private lazy var apiAssembly = APIAssembly(coreAssembly: coreAssembly)
    private lazy var walletBalanceAssembly = WalletBalanceAssembly(coreAssembly: coreAssembly,
                                                                   formattersAssembly: formattersAssembly)
    private lazy var keeperInfoAssembly = KeeperInfoAssembly(coreAssembly: coreAssembly)
    private lazy var confifurationAssembly = ConfigurationAssembly(coreAssembly: coreAssembly)
    
    private lazy var apiV2: API = apiAssembly.apiV2(requestInterceptors: [accessTokenProvider])
    private lazy var apiV1: API = apiAssembly.apiV1()
    
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
            balanceService: walletBalanceAssembly.walletBalanceService(api: apiV2, cacheURL: cacheURL),
            ratesService: ratesAssembly.ratesService(api: apiV2, cacheURL: cacheURL),
            walletProvider: keeperController,
            walletBalanceMapper: walletBalanceAssembly.walletBalanceMapper())
    }
}

private extension WalletCoreAssembly {
    var accessTokenProvider: AccessTokenProvider {
        AccessTokenProvider(configurationController: confifurationAssembly.configurationController(api: apiV1, cacheURL: cacheURL))
    }
}
