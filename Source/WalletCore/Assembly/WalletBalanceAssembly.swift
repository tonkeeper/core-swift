//
//  WalletBalanceAssembly.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation
import TonAPI

final class WalletBalanceAssembly {
    let servicesAssembly: ServicesAssembly
    let formattersAssembly: FormattersAssembly
    let coreAssembly: CoreAssembly
    
    init(servicesAssembly: ServicesAssembly,
         formattersAssembly: FormattersAssembly,
         coreAssembly: CoreAssembly) {
        self.servicesAssembly = servicesAssembly
        self.formattersAssembly = formattersAssembly
        self.coreAssembly = coreAssembly
    }
    
    var walletBalanceController: WalletBalanceController {
        WalletBalanceController(
            balanceService: servicesAssembly.walletBalanceService,
            ratesService: servicesAssembly.ratesService,
            walletProvider: coreAssembly.walletProvider,
            walletBalanceMapper: walletBalanceMapper(),
            transactionsUpdatePublishService: servicesAssembly.transactionsUpdateService
        )
    }
    
    func walletBalanceMapper() -> WalletBalanceMapper {
        let rateConverter = RateConverter()
        let walletItemMapper = WalletItemMapper(intAmountFormatter: formattersAssembly.intAmountFormatter,
                                                amountFormatter: formattersAssembly.amountFormatter,
                                                decimalAmountFormatter: formattersAssembly.decimalAmountFormatter,
                                                rateConverter: rateConverter)
        
        return WalletBalanceMapper(walletItemMapper: walletItemMapper,
                                   amountFormatter: formattersAssembly.amountFormatter,
                                   rateConverter: rateConverter)
    }
}
