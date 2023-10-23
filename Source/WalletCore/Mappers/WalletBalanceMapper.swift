//
//  WalletBalanceMapper.swift
//
//
//  Created by Grigory on 1.7.23..
//

import Foundation
import TonSwift
import BigInt

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
    
    func mapWalletBalance(_ walletBalance: WalletBalance,
                          rates: Rates,
                          currency: Currency) -> WalletBalanceModel {
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
        let header = mapWalletHeader(
            walletBalance: walletBalance,
            tonRate: tonRate,
            tokensRates: tokensRates,
            currency: currency)

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
        
        let pages = mapToPages(ton: tonItems,
                               tokens: tokensTokens,
                               collectibles: collectibles)
        
        let walletState = WalletBalanceModel(header: header,
                                             pages: pages)
        
        return walletState
    }
    
    func emptyBalanceModel(wallet: Wallet) throws -> WalletBalanceModel {
        let contractBuilder = WalletContractBuilder()
        let contract = try contractBuilder.walletContract(
            with: wallet.publicKey,
            contractVersion: wallet.contractVersion
        )
        let address = try contract.address()
        
        let item = walletItemMapper.mapTon(amount: 0, rates: [], currency: wallet.currency)
        
        let section = WalletBalanceModel.Section.token([item])
        let page = WalletBalanceModel.Page(title: "",
                                           sections: [section])
        
        return WalletBalanceModel(
            header: .init(amount: "\(wallet.currency.symbol)0",
                          fullAddress: address.toString(bounceable: false),
                          shortAddress: address.toShortString(bounceable: false)),
            pages: [page])
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
                         tonRate: Rates.Rate?,
                         tokensRates: [Address: Rates.Rate],
                         currency: Currency) -> WalletBalanceModel.Header {
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
        let address = walletBalance.walletAddress
    
        return WalletBalanceModel.Header(
            amount: totalBalanceFormatted,
            fullAddress: address.toString(bounceable: false),
            shortAddress: address.toShortString(bounceable: false)
        )
    }
    
    func mapTokens(_ tokens: [TokenBalance], 
                   tokenRates: [Rates.TokenRate],
                   currency: Currency) -> [WalletItemViewModel] {
        tokens.map { token in
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
            walletItemMapper.mapCollectible(title: collectible.name,
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
