//
//  TokenDetailsProvider.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation

protocol TokenDetailsProvider {
    var output: TokenDetailsControllerOutput? { get set }
    
    func getHeader(walletBalance: WalletBalance,
                   currency: Currency) -> TokenDetailsController.TokenDetailsHeader
    func reloadRate(currency: Currency) async throws
    func handleRecieve()
    func handleSend()
    func handleSwap()
    func handleBuy()
}

extension TokenDetailsProvider {
    func handleBuy() {}
}
