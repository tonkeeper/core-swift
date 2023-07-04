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
    private let intAmountFormatter: IntAmountFormatter
    private let decimalAmountFormatter: DecimalAmountFormatter
    private let bigIntAmountFormatter: BigIntAmountFormatter
    private let rateConverter: RateConverter
    
    init(intAmountFormatter: IntAmountFormatter,
         decimalAmountFormatter: DecimalAmountFormatter,
         bigIntAmountFormatter: BigIntAmountFormatter,
         rateConverter: RateConverter) {
        self.intAmountFormatter = intAmountFormatter
        self.decimalAmountFormatter = decimalAmountFormatter
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
        
        var tokens = [WalletBalanceModel.Token]()
        
        let tonBalanceToken = mapTonBalance(
            walletBalance.tonBalance,
            tonRates: rates.ton,
            title: walletBalance.tonBalance.amount.tonInfo.name,
            image: .ton)
        let previousRevisionsTokens = mapPreviousRevisionBalances(
            walletBalance.previousRevisionsBalances,
            tonRates: rates.ton
        )
        let tokensTokens = mapTokens(
            walletBalance.tokensBalance,
            tokenRates: rates.tokens
        )
        
        tokens.append(tonBalanceToken)
        tokens.append(contentsOf: previousRevisionsTokens)
        tokens.append(contentsOf: tokensTokens)
        
        let tokenSection = WalletBalanceModel.Section.token(tokens)
        
        let collectibles = mapCollectibles(walletBalance.collectibles)
        let collectiblesSection = WalletBalanceModel.Section.collectibles(collectibles)
        
        let pages = mapToPages(tokens: tokens, collectibles: collectibles)
        
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
        let address = try contract.address().toString()
        let leftPart = address.prefix(4)
        let rightPart = address.suffix(4)
        let shortAddress = "\(leftPart)...\(rightPart)"
        
        let token = WalletBalanceModel.Token(title: TonInfo().name,
                                             shortTitle: nil,
                                             price: nil,
                                             priceDiff: nil,
                                             topAmount: nil,
                                             bottomAmount: nil,
                                             image: .ton)
        let section = WalletBalanceModel.Section.token([token])
        let page = WalletBalanceModel.Page(title: "",
                                           sections: [section])
        
        return WalletBalanceModel(
            header: .init(amount: "\(Currency.USD.symbol ?? "")0",
                          fullAddress: address,
                          shortAddress: shortAddress),
            pages: [page])
    }
}

private extension WalletBalanceMapper {
    func mapTonBalance(_ tonBalance: TonBalance,
                       tonRates: [Rates.Rate],
                       title: String,
                       image: Image) -> WalletBalanceModel.Token {
        var topAmount: String?
        var price: String?
        var bottomAmount: String?
    
        topAmount = intAmountFormatter.format(
            amount: tonBalance.amount.quantity,
            fractionDigits: tonBalance.amount.tonInfo.fractionDigits
        )
        
        if let usdRate = tonRates.first(where: { $0.currency == .USD }) {
            let fiatAmount = rateConverter.convert(
                amount: tonBalance.amount.quantity,
                amountFractionLength: tonBalance.amount.tonInfo.fractionDigits,
                rate: usdRate)
            
            bottomAmount = bigIntAmountFormatter.format(
                amount: fiatAmount.amount,
                fractionDigits: fiatAmount.fractionLength,
                maximumFractionDigits: 2,
                symbol: usdRate.currency.symbol)
            
            price = decimalAmountFormatter.format(amount: usdRate.rate, symbol: usdRate.currency.symbol)
        }
        
        return WalletBalanceModel.Token(title: title,
                                        shortTitle: nil,
                                        price: price,
                                        priceDiff: nil,
                                        topAmount: topAmount,
                                        bottomAmount: bottomAmount,
                                        image: image)
    }
    
    func mapPreviousRevisionBalances(_ balances: [TonBalance], tonRates: [Rates.Rate]) -> [WalletBalanceModel.Token] {
        balances
            .filter { $0.amount.quantity > 0 }
            .map { tonBalance in
                return mapTonBalance(tonBalance, tonRates: tonRates, title: "Old wallet", image: .oldWallet)
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
        let address = walletBalance.walletAddress.toString()
        let leftPart = address.prefix(4)
        let rightPart = address.suffix(4)
        let shortAddress = "\(leftPart)...\(rightPart)"
        
        return .init(amount: totalBalanceFormatted, fullAddress: address, shortAddress: shortAddress)
    }
    
    func mapTokens(_ tokens: [TokenBalance], tokenRates: [Rates.TokenRate]) -> [WalletBalanceModel.Token] {
        tokens.map { token in
            let topAmount = bigIntAmountFormatter.format(
                amount: token.amount.quantity,
                fractionDigits: token.amount.tokenInfo.fractionDigits,
                maximumFractionDigits: 2,
                symbol: nil
            )
            
            var price: String?
            var bottomAmount: String?
            
            if let tokenRate = tokenRates.first(where: { $0.tokenInfo == token.amount.tokenInfo }),
               let usdRate = tokenRate.rates.first(where: { $0.currency == .USD }) {
                let fiatAmount = rateConverter.convert(
                    amount: token.amount.quantity,
                    amountFractionLength: token.amount.tokenInfo.fractionDigits,
                    rate: usdRate)
                
                bottomAmount = bigIntAmountFormatter.format(
                    amount: fiatAmount.amount,
                    fractionDigits: fiatAmount.fractionLength,
                    maximumFractionDigits: 2,
                    symbol: usdRate.currency.symbol)
                
                price = decimalAmountFormatter.format(amount: usdRate.rate, symbol: usdRate.currency.symbol)
            }
            
            return WalletBalanceModel.Token(title: token.amount.tokenInfo.name,
                                            shortTitle: token.amount.tokenInfo.symbol,
                                            price: price,
                                            priceDiff: nil,
                                            topAmount: topAmount,
                                            bottomAmount: bottomAmount,
                                            image: .url(token.amount.tokenInfo.imageURL))
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
    
    func mapCollectibles(_ collectibles: [Collectible]) -> [WalletBalanceModel.Collectible] {
        return collectibles.map { collectible in
            var subtitle: String?
            if let collection = collectible.collection {
                subtitle = collection.name
            }
            
            return WalletBalanceModel.Collectible(title: collectible.name,
                                                  subtitle: subtitle,
                                                  imageURL: collectible.imageURL)
        }
    }
    
    func mapToPages(tokens: [WalletBalanceModel.Token],
                    collectibles: [WalletBalanceModel.Collectible]) -> [WalletBalanceModel.Page] {
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
