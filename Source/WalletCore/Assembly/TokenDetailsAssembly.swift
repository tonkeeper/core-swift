//
//  TokenDetailsAssembly.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation

final class TokenDetailsAssembly {
    func tokenDetailsTonController() -> TokenDetailsController {
        let tokenDetailsController = TokenDetailsController(tokenDetailsProvider: tokenDetailsTonProvider())
        return tokenDetailsController
    }
    
    func tokenDetailsTokenController(_ tokenInfo: TokenInfo) -> TokenDetailsController {
        let tokenDetailsController = TokenDetailsController(tokenDetailsProvider: tokenDetailsTokenProvider(tokenInfo: tokenInfo))
        return tokenDetailsController
    }
}

private extension TokenDetailsAssembly {
    func tokenDetailsTonProvider() -> TokenDetailsTonProvider {
        TokenDetailsTonProvider()
    }
    
    func tokenDetailsTokenProvider(tokenInfo: TokenInfo) -> TokenDetailsTokenProvider {
        TokenDetailsTokenProvider(tokenInfo: tokenInfo)
    }
}
