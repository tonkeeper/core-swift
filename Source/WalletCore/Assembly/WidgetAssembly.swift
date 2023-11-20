//
//  WidgetAssembly.swift
//
//
//  Created by Grigory on 30.9.23..
//

import Foundation
import TonAPI

final class WidgetAssembly {
    let formattersAssembly: FormattersAssembly
    let walletBalanceAssembly: WalletBalanceAssembly
    let servicesAssembly: ServicesAssembly
    let coreAssembly: CoreAssembly
    
    init(formattersAssembly: FormattersAssembly,
         walletBalanceAssembly: WalletBalanceAssembly,
         servicesAssembly: ServicesAssembly,
         coreAssembly: CoreAssembly) {
        self.formattersAssembly = formattersAssembly
        self.walletBalanceAssembly = walletBalanceAssembly
        self.servicesAssembly = servicesAssembly
        self.coreAssembly = coreAssembly
    }
    
    func balanceWidgetController() -> BalanceWidgetController {
        BalanceWidgetController(walletProvider: coreAssembly.walletProvider,
                                balanceService: servicesAssembly.walletBalanceService,
                                ratesService: servicesAssembly.ratesService,
                                amountFormatter: formattersAssembly.amountFormatter)
    }
}
