//
//  TokenDetailsAssembly.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation
import TonAPI

struct TokenDetailsAssembly {
    let coreAssembly: CoreAssembly
    let formattersAssembly: FormattersAssembly
    let servicesAssembly: ServicesAssembly
    let apiAssembly: APIAssembly
    
    init(coreAssembly: CoreAssembly,
         formattersAssembly: FormattersAssembly,
         servicesAssembly: ServicesAssembly,
         apiAssembly: APIAssembly) {
        self.formattersAssembly = formattersAssembly
        self.servicesAssembly = servicesAssembly
        self.coreAssembly = coreAssembly
        self.apiAssembly = apiAssembly
    }
    
    func tokenDetailsTonController() -> TokenDetailsController {
        let tokenDetailsController = TokenDetailsController(
            tokenDetailsProvider: tokenDetailsTonProvider(),
            walletProvider: coreAssembly.walletProvider,
            balanceService: servicesAssembly.walletBalanceService
        )
        return tokenDetailsController
    }
    
    func tokenDetailsTokenController(_ tokenInfo: TokenInfo) -> TokenDetailsController {
        let tokenDetailsController = TokenDetailsController(
            tokenDetailsProvider: tokenDetailsTokenProvider(
                tokenInfo: tokenInfo
            ),
            walletProvider: coreAssembly.walletProvider,
            balanceService: servicesAssembly.walletBalanceService)
        return tokenDetailsController
    }
    
    func chartController() -> ChartController {
        ChartController(chartService: servicesAssembly.chartService,
                        ratesService: servicesAssembly.ratesService,
                        decimalAmountFormatter: formattersAssembly.decimalAmountFormatter)
    }
}

private extension TokenDetailsAssembly {
    func tokenDetailsTonProvider() -> TokenDetailsTonProvider {
        TokenDetailsTonProvider(walletItemMapper: walletItemMapper(),
                                ratesService: servicesAssembly.ratesService)
    }
    
    func tokenDetailsTokenProvider(tokenInfo: TokenInfo) -> TokenDetailsTokenProvider {
        TokenDetailsTokenProvider(tokenInfo: tokenInfo,
                                  walletItemMapper: walletItemMapper(),
                                  ratesService: servicesAssembly.ratesService)
    }
    
    func walletItemMapper() -> WalletItemMapper {
        WalletItemMapper(
            intAmountFormatter: formattersAssembly.intAmountFormatter,
            amountFormatter: formattersAssembly.amountFormatter,
            decimalAmountFormatter: formattersAssembly.decimalAmountFormatter,
            rateConverter: RateConverter()
        )
    }
}
