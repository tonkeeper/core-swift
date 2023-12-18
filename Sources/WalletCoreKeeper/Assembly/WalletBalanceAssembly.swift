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
    let storesAssembly: StoresAssembly
    
    init(servicesAssembly: ServicesAssembly,
         formattersAssembly: FormattersAssembly,
         coreAssembly: CoreAssembly,
         storesAssembly: StoresAssembly) {
        self.servicesAssembly = servicesAssembly
        self.formattersAssembly = formattersAssembly
        self.coreAssembly = coreAssembly
        self.storesAssembly = storesAssembly
    }
    
    func balanceController() -> BalanceController {
        BalanceController(balanceStore: storesAssembly.balanceStore,
                          ratesStore: storesAssembly.ratesStore,
                          walletProvider: coreAssembly.walletProvider,
                          walletBalanceMapper: walletBalanceMapper())
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
