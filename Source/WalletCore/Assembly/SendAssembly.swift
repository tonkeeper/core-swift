//
//  SendAssembly.swift
//  
//
//  Created by Grigory on 5.7.23..
//

import Foundation
import TonAPI

final class SendAssembly {
    
    let formattersAssembly: FormattersAssembly
    let ratesAssembly: RatesAssembly
    let balanceAssembly: WalletBalanceAssembly
    
    init(formattersAssembly: FormattersAssembly,
         ratesAssembly: RatesAssembly,
         balanceAssembly: WalletBalanceAssembly) {
        self.formattersAssembly = formattersAssembly
        self.ratesAssembly = ratesAssembly
        self.balanceAssembly = balanceAssembly
    }
    
    func sendInputController(api: API, cacheURL: URL, walletProvider: WalletProvider) -> SendInputController {
        return SendInputController(bigIntAmountFormatter: formattersAssembly.bigIntAmountFormatter,
                                   ratesService: ratesAssembly.ratesService(api: api, cacheURL: cacheURL),
                                   balanceService: balanceAssembly.walletBalanceService(api: api, cacheURL: cacheURL),
                                   balanceMapper: balanceAssembly.walletBalanceMapper(),
                                   walletProvider: walletProvider,
                                   rateConverter: RateConverter())
    }
}
