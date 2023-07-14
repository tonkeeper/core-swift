//
//  TokenDetailsProvider.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation

protocol TokenDetailsProvider {
    func getHeader(walletBalance: WalletBalance,
                   currency: Currency) -> TokenDetailsController.TokenDetailsHeader
    func reloadRate(currency: Currency) async throws
}
