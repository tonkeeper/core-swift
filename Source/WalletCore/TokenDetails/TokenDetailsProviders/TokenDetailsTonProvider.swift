//
//  TokenDetailsTonProvider.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation

struct TokenDetailsTonProvider: TokenDetailsProvider {
    func getHeader() -> TokenDetailsController.TokenDetailsHeader {
        return .init(name: "", amount: "", fiatAmount: "", price: "", image: .ton, buttons: [.send, .receive, .buy, .swap])
    }
}
