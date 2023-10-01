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
    private let bigIntAmountFormatter: BigIntAmountFormatter
    private let rateConverter: RateConverter
    
    init(walletItemMapper: WalletItemMapper,
         bigIntAmountFormatter: BigIntAmountFormatter,
         rateConverter: RateConverter) {
        self.walletItemMapper = walletItemMapper
        self.bigIntAmountFormatter = bigIntAmountFormatter
        self.rateConverter = rateConverter
    }
    
    func mapWalletBalance(_ walletBalance: WalletBalance, rates: Rates) -> WalletBalanceModel {
        let tonRate = rates.ton.first(where: { $0.currency == .USD })
        
        let tokensRates = walletBalance.tokensBalance.reduce([Address: Rates.Rate]()) { dictionary, tokenBalance -> [Address: Rates.Rate] in
            var dictionary = dictionary
            if let rate = rates.tokens
                .first(where: { $0.tokenInfo == tokenBalance.amount.tokenInfo })?
                .rates
                .first(where: { $0.currency == .USD }) {
                dictionary[tokenBalance.amount.tokenInfo.address] = rate
            }
            return dictionary
        }
        let header = mapWalletHeader(
            walletBalance: walletBalance,
            tonRate: tonRate,
            tokensRates: tokensRates)
        
        var items = [WalletItemViewModel]()
        
        let tonBalanceToken = walletItemMapper.mapTon(amount: walletBalance.tonBalance.amount.quantity,
                                                      rates: rates.ton,
                                                      currency: .USD)
        let previousRevisionsTokens = mapPreviousRevisionBalances(
            walletBalance.previousRevisionsBalances,
            tonRates: rates.ton
        )
        let tokensTokens = mapTokens(
            walletBalance.tokensBalance,
            tokenRates: rates.tokens
        )
        
        items.append(tonBalanceToken)
        items.append(contentsOf: previousRevisionsTokens)
        items.append(contentsOf: tokensTokens)
        
        let collectibles = mapCollectibles(walletBalance.collectibles)
        
        let pages = mapToPages(tokens: items, collectibles: collectibles)
        
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
        
        let item = walletItemMapper.mapTon(amount: 0, rates: [], currency: .USD)
        
        let section = WalletBalanceModel.Section.token([item])
        let page = WalletBalanceModel.Page(title: "",
                                           sections: [section])
        
        return WalletBalanceModel(
            header: .init(amount: "\(Currency.USD.symbol ?? "")0",
                          fullAddress: address.toString(bounceable: false),
                          shortAddress: address.toShortString(bounceable: false)),
            pages: [page])
    }
}

private extension WalletBalanceMapper {
    func mapPreviousRevisionBalances(_ balances: [TonBalance], tonRates: [Rates.Rate]) -> [WalletItemViewModel] {
        balances
            .filter { $0.amount.quantity > 0 }
            .map { tonBalance in
                walletItemMapper.mapOldWalletTon(amount: tonBalance.amount.quantity,
                                                 rates: tonRates,
                                                 currency: .USD)
            }
    }
    
    func mapWalletHeader(walletBalance: WalletBalance,
                         tonRate: Rates.Rate?,
                         tokensRates: [Address: Rates.Rate]) -> WalletBalanceModel.Header {
        let totalBalanceAmount = calculateTotalBalance(walletBalance: walletBalance,
                              tonRate: tonRate,
                              tokensRates: tokensRates)
        let totalBalanceFormatted = bigIntAmountFormatter.format(
            amount: totalBalanceAmount.amount,
            fractionDigits: totalBalanceAmount.fractionLength,
            maximumFractionDigits: 2,
            symbol: Currency.USD.symbol
        )
        let address = walletBalance.walletAddress
    
        return WalletBalanceModel.Header(
            amount: totalBalanceFormatted,
            fullAddress: address.toString(bounceable: false),
            shortAddress: address.toShortString(bounceable: false)
        )
    }
    
    func mapTokens(_ tokens: [TokenBalance], tokenRates: [Rates.TokenRate]) -> [WalletItemViewModel] {
        tokens.map { token in
            let rates = tokenRates.first(where: { $0.tokenInfo == token.amount.tokenInfo })
            return walletItemMapper.mapToken(amount: token.amount.quantity,
                                             rates: rates?.rates ?? [],
                                             tokenInfo: token.amount.tokenInfo,
                                             currency: .USD,
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
                                            subtitle: collectible.collection?.name,
                                            imageURL: collectible.preview.size500,
                                            address: collectible.address)
        }
    }
    
    func mapToPages(tokens: [WalletItemViewModel],
                    collectibles: [WalletCollectibleItemViewModel]) -> [WalletBalanceModel.Page] {
        var pages = [WalletBalanceModel.Page]()
        let tokensCount = tokens.count
        let collectiblesCount = Int(ceil(CGFloat(collectibles.count) / 3)) * 2
        
        let tokensSection = WalletBalanceModel.Section.token(tokens)
        let collectiblesSection = WalletBalanceModel.Section.collectibles(collectibles)
        
        if tokensCount + collectiblesCount <= 10 {
            var sections = [WalletBalanceModel.Section]()
            if tokensCount > 0 {
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
        if tokensCount > 0 { sections.append(tokensSection)}
        
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
}
