//
//  TokenDetailsController.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation

public final class TokenDetailsController {
    public struct TokenDetailsHeader {
        enum Button {
            case send
            case receive
            case buy
            case swap
        }
        
        let name: String?
        let amount: String?
        let fiatAmount: String?
        let price: String?
        let image: Image
        let buttons: [Button]
    }
    
    private let tokenDetailsProvider: TokenDetailsProvider
    
    init(tokenDetailsProvider: TokenDetailsProvider) {
        self.tokenDetailsProvider = tokenDetailsProvider
    }
    
    public func getTokenHeader() -> TokenDetailsHeader {
        tokenDetailsProvider.getHeader()
    }
}
