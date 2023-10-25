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
    let keeperAssembly: KeeperAssembly
    let servicesAssembly: ServicesAssembly
    
    init(formattersAssembly: FormattersAssembly,
         walletBalanceAssembly: WalletBalanceAssembly,
         keeperAssembly: KeeperAssembly,
         servicesAssembly: ServicesAssembly) {
        self.formattersAssembly = formattersAssembly
        self.walletBalanceAssembly = walletBalanceAssembly
        self.keeperAssembly = keeperAssembly
        self.servicesAssembly = servicesAssembly
    }
    
    func balanceWidgetController() -> BalanceWidgetController {
        BalanceWidgetController(walletProvider: keeperAssembly.keeperController,
                                balanceService: servicesAssembly.walletBalanceService,
                                ratesService: servicesAssembly.ratesService,
                                amountFormatter: formattersAssembly.amountFormatter)
    }
}
