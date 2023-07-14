//
//  TokenDetailsTokenProvider.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation

struct TokenDetailsTokenProvider: TokenDetailsProvider {
    
    private let tokenInfo: TokenInfo
    
    init(tokenInfo: TokenInfo) {
        self.tokenInfo = tokenInfo
    }
    
    func getHeader() -> TokenDetailsController.TokenDetailsHeader {
        return .init(name: "", amount: "", fiatAmount: "", price: "", image: .ton, buttons: [.send, .receive, .swap])
    }
}
