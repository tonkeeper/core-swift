//
//  TokenDetailsProvider.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation
import WalletCoreCore

protocol TokenDetailsProvider {
    var output: TokenDetailsControllerOutput? { get set }
    
    var hasChart: Bool { get }
    var hasAbout: Bool { get }
    
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
