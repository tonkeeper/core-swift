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
    let ratesAssembly: RatesAssembly
    
    init(formattersAssembly: FormattersAssembly,
         walletBalanceAssembly: WalletBalanceAssembly,
         ratesAssembly: RatesAssembly) {
        self.formattersAssembly = formattersAssembly
        self.walletBalanceAssembly = walletBalanceAssembly
        self.ratesAssembly = ratesAssembly
    }
    
    func balanceWidgetController(walletProvider: WalletProvider,
                                 api: API,
                                 cacheURL: URL) -> BalanceWidgetController {
        BalanceWidgetController(walletProvider: walletProvider,
                                balanceService: walletBalanceAssembly.walletBalanceService(api: api, cacheURL: cacheURL),
                                ratesService: ratesAssembly.ratesService(api: api, cacheURL: cacheURL),
                                amountFormatter: formattersAssembly.amountFormatter)
    }
}
