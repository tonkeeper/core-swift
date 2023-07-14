//
//  WalletItemMapper.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation
import BigInt

struct WalletItemMapper {
    private let intAmountFormatter: IntAmountFormatter
    private let bigIntAmountFormatter: BigIntAmountFormatter
    private let decimalAmountFormatter: DecimalAmountFormatter
    private let rateConverter: RateConverter
    
    init(intAmountFormatter: IntAmountFormatter,
         bigIntAmountFormatter: BigIntAmountFormatter,
         decimalAmountFormatter: DecimalAmountFormatter,
         rateConverter: RateConverter) {
        self.intAmountFormatter = intAmountFormatter
        self.bigIntAmountFormatter = bigIntAmountFormatter
        self.decimalAmountFormatter = decimalAmountFormatter
        self.rateConverter = rateConverter
    }
    
    func mapTon(amount: Int64,
                rates: [Rates.Rate],
                currency: Currency) -> WalletItemViewModel {
        let tonInfo = TonInfo()
        return mapTonToWalletItemViewModel(
            amount: amount,
            rates: rates,
            tonInfo: tonInfo,
            currency: currency,
            title: tonInfo.name,
            image: .ton,
            type: .ton)
    }
    
    func mapOldWalletTon(amount: Int64,
                         rates: [Rates.Rate],
                         currency: Currency) -> WalletItemViewModel {
        let tonInfo = TonInfo()
        return mapTonToWalletItemViewModel(
            amount: amount,
            rates: rates,
            tonInfo: tonInfo,
            currency: currency,
            title: "Old wallet",
            image: .oldWallet,
            type: .old)
    }
    
    func mapToken(amount: BigInt,
                  rates: [Rates.Rate],
                  tokenInfo: TokenInfo,
                  currency: Currency,
                  maximumFractionDigits: Int) -> WalletItemViewModel {
        mapTokenToWalletItemViewModel(amount: amount,
                                      rates: rates,
                                      tokenInfo: tokenInfo,
                                      currency: currency,
                                      maximumFractionDigits: maximumFractionDigits)
    }
    
    func mapCollectible(title: String?,
                        subtitle: String?,
                        imageURL: URL?) -> WalletCollectibleItemViewModel {
        WalletCollectibleItemViewModel(title: title, subtitle: subtitle, imageURL: imageURL)
    }
}

private extension WalletItemMapper {
    func mapTonToWalletItemViewModel(amount: Int64,
                                     rates: [Rates.Rate],
                                     tonInfo: TonInfo,
                                     currency: Currency,
                                     title: String,
                                     image: Image,
                                     type: WalletItemViewModel.ItemType) -> WalletItemViewModel {
        let tokenAmount = intAmountFormatter.format(
            amount: amount,
            fractionDigits: tonInfo.fractionDigits
        )
        
        var price: String?
        var fiatAmount: String?
        
        if let currencyRate = rates.first(where: { $0.currency == currency }) {
            let fiat = rateConverter.convert(amount: amount,
                                             amountFractionLength: tonInfo.fractionDigits,
                                             rate: currencyRate)
            
            fiatAmount = bigIntAmountFormatter.format(
                amount: fiat.amount,
                fractionDigits: fiat.fractionLength,
                maximumFractionDigits: 2,
                symbol: currency.symbol
            )
            
            price = decimalAmountFormatter.format(amount: currencyRate.rate, symbol: currency.symbol)
        }
        
        return WalletItemViewModel(
            type: type,
            image: image,
            leftTitle: tonInfo.name,
            rightTitle: tonInfo.symbol,
            leftSubtitle: price,
            rightSubtitle: nil,
            rightValue: tokenAmount,
            rightSubvalue: fiatAmount
        )
    }
    
    func mapTokenToWalletItemViewModel(amount: BigInt,
                                       rates: [Rates.Rate],
                                       tokenInfo: TokenInfo,
                                       currency: Currency,
                                       maximumFractionDigits: Int) -> WalletItemViewModel {
        let tokenAmount = bigIntAmountFormatter.format(
            amount: amount,
            fractionDigits: tokenInfo.fractionDigits,
            maximumFractionDigits: maximumFractionDigits,
            symbol: nil
        )
        
        var price: String?
        var fiatAmount: String?
        
        if let currencyRate = rates.first(where: { $0.currency == currency}) {
            let fiat = rateConverter.convert(amount: amount,
                                             amountFractionLength: tokenInfo.fractionDigits,
                                             rate: currencyRate)
            
            fiatAmount = bigIntAmountFormatter.format(amount: fiat.amount,
                                                      fractionDigits: fiat.fractionLength,
                                                      maximumFractionDigits: maximumFractionDigits,
                                                      symbol: currency.symbol)
            
            price = decimalAmountFormatter.format(amount: currencyRate.rate, symbol: currency.symbol)
        }
        
        return WalletItemViewModel(
            type: .token(tokenInfo),
            image: .url(tokenInfo.imageURL),
            leftTitle: tokenInfo.name,
            rightTitle: tokenInfo.symbol,
            leftSubtitle: price,
            rightSubtitle: nil,
            rightValue: tokenAmount,
            rightSubvalue: fiatAmount
        )
    }
}
 
