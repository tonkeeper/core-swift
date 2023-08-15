//
//  TokenDetailsTokenProvider.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation
import BigInt

struct TokenDetailsTokenProvider: TokenDetailsProvider {
    weak var output: TokenDetailsControllerOutput?
    
    var hasChart: Bool { false }
    
    private let tokenInfo: TokenInfo
    private let walletItemMapper: WalletItemMapper
    private let ratesService: RatesService
    
    init(tokenInfo: TokenInfo,
         walletItemMapper: WalletItemMapper,
         ratesService: RatesService) {
        self.tokenInfo = tokenInfo
        self.walletItemMapper = walletItemMapper
        self.ratesService = ratesService
    }
    
    func getHeader(walletBalance: WalletBalance,
                   currency: Currency) -> TokenDetailsController.TokenDetailsHeader {
        let tokenBalance = walletBalance.tokensBalance.first(where: { $0.amount.tokenInfo == tokenInfo })?.amount.quantity ?? BigInt("0")
        let tokenRates = (try? ratesService.getRates().tokens.first(where: { $0.tokenInfo == tokenInfo })?.rates) ?? []
        let itemViewModel = walletItemMapper.mapToken(amount: tokenBalance,
                                                      rates: tokenRates,
                                                      tokenInfo: tokenInfo,
                                                      currency: currency,
                                                      maximumFractionDigits: tokenInfo.fractionDigits)
        
        var price: String?
        if let priceValue = itemViewModel.leftSubtitle {
            price = "Price: \(priceValue)"
        }
        
        return TokenDetailsController.TokenDetailsHeader(name: tokenInfo.name,
                                                         amount: itemViewModel.rightValue ?? "", 
                                                         fiatAmount: itemViewModel.rightSubvalue,
                                                         price: price,
                                                         image: .url(tokenInfo.imageURL),
                                                         buttons: [.send, .receive, .swap])
    }
    
    func reloadRate(currency: Currency) async throws {
        try await _ = ratesService.loadRates(tonInfo: TonInfo(), tokens: [tokenInfo], currencies: [currency])
    }
    
    func handleRecieve() {
        output?.handleTokenRecieve(tokenInfo: tokenInfo)
    }
    
    func handleSend() {
        output?.handleTokenSend(tokenInfo: tokenInfo)
    }
    
    func handleSwap() {
        output?.handleTokenSwap(tokenInfo: tokenInfo)
    }
}
