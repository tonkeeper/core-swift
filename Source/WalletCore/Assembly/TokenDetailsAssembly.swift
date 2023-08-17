//
//  TokenDetailsAssembly.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation
import TonAPI

struct TokenDetailsAssembly {
    let formattersAssembly: FormattersAssembly
    
    init(formattersAssembly: FormattersAssembly) {
        self.formattersAssembly = formattersAssembly
    }
    
    func tokenDetailsTonController(ratesService: RatesService,
                                   balaceService: WalletBalanceService,
                                   walletProvider: WalletProvider) -> TokenDetailsController {
        let tokenDetailsController = TokenDetailsController(
            tokenDetailsProvider: tokenDetailsTonProvider(ratesService: ratesService),
            walletProvider: walletProvider,
            balanceService: balaceService
        )
        return tokenDetailsController
    }
    
    func tokenDetailsTokenController(_ tokenInfo: TokenInfo,
                                     ratesService: RatesService,
                                     balaceService: WalletBalanceService,
                                     walletProvider: WalletProvider) -> TokenDetailsController {
        let tokenDetailsController = TokenDetailsController(
            tokenDetailsProvider: tokenDetailsTokenProvider(tokenInfo: tokenInfo,
                                                            ratesService: ratesService),
            walletProvider: walletProvider,
            balanceService: balaceService)
        return tokenDetailsController
    }
    
    func chartController(api: API) -> ChartController {
        ChartController(chartService: chartService(api: api))
    }
}

private extension TokenDetailsAssembly {
    func tokenDetailsTonProvider(ratesService: RatesService) -> TokenDetailsTonProvider {
        TokenDetailsTonProvider(walletItemMapper: walletItemMapper(),
                                ratesService: ratesService)
    }
    
    func tokenDetailsTokenProvider(tokenInfo: TokenInfo,
                                   ratesService: RatesService) -> TokenDetailsTokenProvider {
        TokenDetailsTokenProvider(tokenInfo: tokenInfo,
                                  walletItemMapper: walletItemMapper(),
                                  ratesService: ratesService)
    }
    
    func walletItemMapper() -> WalletItemMapper {
        WalletItemMapper(
            intAmountFormatter: formattersAssembly.intAmountFormatter,
            bigIntAmountFormatter: formattersAssembly.bigIntAmountFormatter,
            decimalAmountFormatter: formattersAssembly.decimalAmountFormatter,
            rateConverter: RateConverter()
        )
    }
    
    func chartService(api: API) -> ChartService {
        ChartServiceImplementation(api: api)
    }
}
