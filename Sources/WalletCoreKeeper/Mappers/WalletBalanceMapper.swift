//
//  WalletBalanceMapper.swift
//
//
//  Created by Grigory on 1.7.23..
//

import Foundation
import TonSwift
import BigInt
import WalletCoreCore

struct WalletBalanceMapper {
    private let walletItemMapper: WalletItemMapper
    private let amountFormatter: AmountFormatter
    private let rateConverter: RateConverter
    
    init(walletItemMapper: WalletItemMapper,
         amountFormatter: AmountFormatter,
         rateConverter: RateConverter) {
        self.walletItemMapper = walletItemMapper
        self.amountFormatter = amountFormatter
        self.rateConverter = rateConverter
    }

    func mapBalance(_ walletBalanceState: WalletBalanceState,
                          rates: Rates,
                          currency: Currency,
                          isOutdated: Bool) -> WalletBalanceModel {
        let subtitle: WalletBalanceModel.Header.Subtitle
        if isOutdated {
            let formatter = DateFormatter()
            formatter.locale = Locale.init(identifier: "EN")
            formatter.dateFormat = "d MMM, HH:mm"
            let date = formatter.string(from: walletBalanceState.date)
            subtitle = .date("Updated on \(date)")
        } else {
            subtitle = .address(walletBalanceState.balance.walletAddress.toShortString(bounceable: false))
        }
        
        let pages = mapPages(
            walletBalanceState.balance,
            rates: rates,
            currency: currency
        )
        let header = mapWalletHeader(
            walletBalance: walletBalanceState.balance,
            rates: rates,
            subtitle: subtitle,
            currency: currency
        )
        
        return WalletBalanceModel(
            header: header,
            pages: pages
        )
    }
    
    func mapPages(_ walletBalance: WalletBalance,
                  rates: Rates,
                  currency: Currency) -> [WalletBalanceModel.Page] {
        
        let tonBalanceToken = walletItemMapper.mapTon(amount: walletBalance.tonBalance.amount.quantity,
                                                      rates: rates.ton,
                                                      currency: currency)
        let previousRevisionsTokens = mapPreviousRevisionBalances(
            walletBalance.previousRevisionsBalances,
            tonRates: rates.ton,
            currency: currency
        )
        let tokensTokens = mapTokens(
            walletBalance.tokensBalance,
            tokenRates: rates.tokens,
            currency: currency
        )
        
        let tonItems = [tonBalanceToken] + previousRevisionsTokens
          
        let collectibles = mapCollectibles(walletBalance.collectibles)
        
        return mapToPages(ton: tonItems,
                          tokens: tokensTokens,
                          collectibles: collectibles)
    }
}

private extension WalletBalanceMapper {
    func mapPreviousRevisionBalances(_ balances: [TonBalance],
                                     tonRates: [Rates.Rate],
                                     currency: Currency) -> [WalletItemViewModel] {
        balances
            .filter { $0.amount.quantity > 0 }
            .map { tonBalance in
                walletItemMapper.mapOldWalletTon(amount: tonBalance.amount.quantity,
                                                 rates: tonRates,
                                                 currency: currency)
            }
    }
    
    func mapWalletHeader(walletBalance: WalletBalance,
                         rates: Rates,
                         subtitle: WalletBalanceModel.Header.Subtitle,
                         currency: Currency) -> WalletBalanceModel.Header {
        let tonRate = rates.ton.first(where: { $0.currency == currency })
        
        let tokensRates = walletBalance.tokensBalance.reduce([Address: Rates.Rate]()) { dictionary, tokenBalance -> [Address: Rates.Rate] in
            var dictionary = dictionary
            if let rate = rates.tokens
                .first(where: { $0.tokenInfo == tokenBalance.amount.tokenInfo })?
                .rates
                .first(where: { $0.currency == currency }) {
                dictionary[tokenBalance.amount.tokenInfo.address] = rate
            }
            return dictionary
        }
        
        let totalBalanceAmount = calculateTotalBalance(
            walletBalance: walletBalance,
            tonRate: tonRate,
            tokensRates: tokensRates
        )
        let totalBalanceFormatted = amountFormatter.formatAmountWithoutFractionIfThousand(
            totalBalanceAmount.amount,
            fractionDigits: totalBalanceAmount.fractionLength,
            maximumFractionDigits: 2,
            currency: currency
        )
        return WalletBalanceModel.Header(
            amount: totalBalanceFormatted,
            subtitle: subtitle
        )
    }
    
    func mapTokens(_ tokens: [TokenBalance], 
                   tokenRates: [Rates.TokenRate],
                   currency: Currency) -> [WalletItemViewModel] {
        tokens.compactMap { token -> WalletItemViewModel? in
            guard !token.amount.quantity.isZero else { return nil }
            let rates = tokenRates.first(where: { $0.tokenInfo == token.amount.tokenInfo })
            return walletItemMapper.mapToken(amount: token.amount.quantity,
                                             rates: rates?.rates ?? [],
                                             tokenInfo: token.amount.tokenInfo,
                                             currency: currency,
                                             maximumFractionDigits: 2)
        }
    }
    
    func calculateTotalBalance(walletBalance: WalletBalance,
                               tonRate: Rates.Rate?,
                               tokensRates: [Address: Rates.Rate]) -> (amount: BigInt, fractionLength: Int) {
        var maximumFractionLength = 0
        var balanceItems = [(amount: BigInt, fractionLength: Int)]()
        if let tonRate = tonRate {
            let tonBalanceItem = rateConverter.convert(
                amount: walletBalance.tonBalance.amount.quantity,
                amountFractionLength: walletBalance.tonBalance.amount.tonInfo.fractionDigits,
                rate: tonRate)
            balanceItems.append(tonBalanceItem)
            maximumFractionLength = max(tonBalanceItem.fractionLength, maximumFractionLength)
            
            for previousRevisionsBalance in walletBalance.previousRevisionsBalances {
                let balanceItem = rateConverter.convert(
                    amount: previousRevisionsBalance.amount.quantity,
                    amountFractionLength: previousRevisionsBalance.amount.tonInfo.fractionDigits,
                    rate: tonRate)
                balanceItems.append(balanceItem)
                maximumFractionLength = max(balanceItem.fractionLength, maximumFractionLength)
            }
        }
        
        let tokenBalanceItems = walletBalance.tokensBalance.compactMap { token -> (amount: BigInt, fractionLength: Int)? in
            guard let rate = tokensRates[token.amount.tokenInfo.address] else {
                return nil
            }
            let balance = rateConverter.convert(
                amount: token.amount.quantity,
                amountFractionLength: token.amount.tokenInfo.fractionDigits,
                rate: rate)
            maximumFractionLength = max(balance.fractionLength, maximumFractionLength)
            return balance
        }
        balanceItems.append(contentsOf: tokenBalanceItems)
        
        var sum = BigInt(stringLiteral: "0")
        for item in balanceItems {
            if item.fractionLength < maximumFractionLength {
                var itemAmount = item.amount
                itemAmount *= BigInt(stringLiteral: "1" + String(repeating: "0", count: maximumFractionLength - item.fractionLength))
                sum += itemAmount
            } else {
                sum += item.amount
            }
        }
        return (sum, maximumFractionLength)
    }
    
    func mapCollectibles(_ collectibles: [Collectible]) -> [WalletCollectibleItemViewModel] {
        return collectibles.map { collectible in
            walletItemMapper.mapCollectible(title: collectible.name ?? collectible.address.toShortString(bounceable: false),
                                            subtitle: collectible.collection?.name ?? .singleNFT,
                                            imageURL: collectible.preview.size500,
                                            address: collectible.address)
        }
    }
    
    func mapToPages(ton: [WalletItemViewModel],
                    tokens: [WalletItemViewModel],
                    collectibles: [WalletCollectibleItemViewModel]) -> [WalletBalanceModel.Page] {
        var pages = [WalletBalanceModel.Page]()
        let tokensCount = ton.count + tokens.count
        let collectiblesCount = Int(ceil(CGFloat(collectibles.count) / 3)) * 2
        
        let tonSection = WalletBalanceModel.Section.token(ton)
        let tokensSection = WalletBalanceModel.Section.token(tokens)
        let collectiblesSection = WalletBalanceModel.Section.collectibles(collectibles)
        
        if tokensCount + collectiblesCount <= 10 {
            var sections = [WalletBalanceModel.Section]()
            if tokensCount > 0 {
                sections.append(tonSection)
                sections.append(tokensSection)
            }
            if collectiblesCount > 0 {
                sections.append(collectiblesSection)
            }
            pages.append(.init(title: "", sections: sections))
            return pages
        }
        
        if tokensCount + collectiblesCount > 10 && collectiblesCount != 0 {
            let collectiblesPage = WalletBalanceModel.Page(
                title: .collectiblesTabTitle,
                sections: [collectiblesSection])
            pages.append(collectiblesPage)
        }
        
        var sections = [WalletBalanceModel.Section]()
        if tokensCount > 0 {
            sections.append(tonSection)
            sections.append(tokensSection)
        }
        
        let page = WalletBalanceModel.Page(
            title: .tokensTabTitle,
            sections: sections
        )
        
        pages.insert(page, at: 0)
        
        return pages
    }
}

private extension String {
    static let collectiblesTabTitle = "Collectibles"
    static let tokensTabTitle = "Tokens"
    static let singleNFT = "Single NFT"
}
