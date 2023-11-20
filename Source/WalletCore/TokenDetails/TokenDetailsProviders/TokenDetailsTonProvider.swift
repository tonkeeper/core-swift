//
//  TokenDetailsTonProvider.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation
import WalletCoreCore

struct TokenDetailsTonProvider: TokenDetailsProvider {
    weak var output: TokenDetailsControllerOutput?
    
    var hasChart: Bool { true }
    var hasAbout: Bool { true }

    private let walletItemMapper: WalletItemMapper
    private let ratesService: RatesService
    
    init(walletItemMapper: WalletItemMapper,
         ratesService: RatesService) {
        self.walletItemMapper = walletItemMapper
        self.ratesService = ratesService
    }

    func getHeader(walletBalance: WalletBalance,
                   currency: Currency) -> TokenDetailsController.TokenDetailsHeader {
        let tonRates = (try? ratesService.getRates().ton) ?? []
    
        let itemViewModel = walletItemMapper.mapTon(amount: walletBalance.tonBalance.amount.quantity,
                                                    rates: tonRates,
                                                    currency: currency)
        
        var price: String?
        if let priceValue = itemViewModel.leftSubtitle {
            price = "Price: \(priceValue)"
        }
        
        return .init(name: itemViewModel.leftTitle,
                     amount: itemViewModel.rightValue ?? "",
                     fiatAmount: itemViewModel.rightSubvalue,
                     price: price,
                     image: .ton,
                     buttons: [.send, .receive, .buy])
    }
    
    func reloadRate(currency: Currency) async throws {
        try await _ = ratesService.loadRates(tonInfo: TonInfo(), tokens: [], currencies: Currency.allCases)
    }
    
    func handleRecieve() {
        output?.handleTonRecieve()
    }
    
    func handleBuy() {
        output?.handleTonBuy()
    }
    
    func handleSend() {
        output?.handleTonSend()
    }
    
    func handleSwap() {
        output?.handleTonSwap()
    }
}
