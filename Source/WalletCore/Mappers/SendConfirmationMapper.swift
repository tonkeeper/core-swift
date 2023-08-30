//
//  SendConfirmationMapper.swift
//
//
//  Created by Grigory on 12.7.23..
//

import Foundation
import BigInt

struct SendConfirmationMapper {
    private let bigIntAmountFormatter: BigIntAmountFormatter
    
    init(bigIntAmountFormatter: BigIntAmountFormatter) {
        self.bigIntAmountFormatter = bigIntAmountFormatter
    }
    
    func mapItemTransferModel(_ itemTransferModel: ItemTransferModel,
                              recipientAddress: String?,
                              recipientName: String?,
                              fee: Int64?,
                              comment: String?,
                              rate: Rates.Rate?,
                              tonRate: Rates.Rate?) -> SendTransactionViewModel.SendTokenModel {
        let token: FormatterTokenInfo
        let image: Image
        let name: String
        switch itemTransferModel.transferItem {
        case .token(_, let tokenInfo):
            name = "\(tokenInfo.symbol ?? "Token") Transfer"
            token = tokenInfo
            image = .url(tokenInfo.imageURL)
        case .ton:
            name = "Ton Transfer"
            token = TonInfo()
            image = .ton
        }
        
        return map(name: name,
                   image: image,
                   recipientAddress: recipientAddress,
                   recipientName: recipientName,
                   token: token,
                   amount: itemTransferModel.amount,
                   fee: fee,
                   comment: comment,
                   rate: rate,
                   tonRate: tonRate)
    }
    
    func mapAction(action: TransferTransactionInfo.Action,
                   fee: Int64?,
                   comment: String?,
                   rate: Rates.Rate?,
                   tonRate: Rates.Rate?) -> SendTransactionViewModel.SendTokenModel {
        let itemTranferModel = ItemTransferModel(transferItem: action.transferItem,
                                                 amount: action.amount)
        return mapItemTransferModel(itemTranferModel,
                                    recipientAddress: action.recipient.address?.shortString,
                                    recipientName: action.recipient.name,
                                    fee: fee,
                                    comment: comment,
                                    rate: rate,
                                    tonRate: tonRate)
    }
}

private extension SendConfirmationMapper {
    func map(name: String,
             image: Image,
             recipientAddress: String?,
             recipientName: String?,
             token: FormatterTokenInfo,
             amount: BigInt,
             fee: Int64?,
             comment: String?,
             rate: Rates.Rate?,
             tonRate: Rates.Rate?) -> SendTransactionViewModel.SendTokenModel {
        let amountFormatted = bigIntAmountFormatter.format(amount: amount,
                                                           fractionDigits: token.fractionDigits,
                                                           maximumFractionDigits: token.fractionDigits,
                                                           symbol: nil)
        
        let tonInfo = TonInfo()
        
        var feeTonString: String?
        var feeFiatString: String?
        var amountFiatString: String?
        let rateConverter = RateConverter()
        if let rate = rate {
            let fiat = rateConverter.convert(amount: amount, amountFractionLength: token.fractionDigits, rate: rate)
            let fiatFormatted = bigIntAmountFormatter.format(amount: fiat.amount,
                                                             fractionDigits: fiat.fractionLength,
                                                             maximumFractionDigits: 2,
                                                             symbol: rate.currency.symbol)
            amountFiatString = "≈\(fiatFormatted)"
        }
        if let fee = fee {
            let feeTon = bigIntAmountFormatter.format(amount: BigInt(fee),
                                                      fractionDigits: tonInfo.fractionDigits,
                                                      maximumFractionDigits: tonInfo.fractionDigits,
                                                      symbol: nil)
            feeTonString = "≈\(feeTon) \(tonInfo.symbol)"
            if let tonRate = tonRate {
                let feeFiat = rateConverter.convert(amount: fee, amountFractionLength: tonInfo.fractionDigits, rate: tonRate)
                let feeFiatFormatted = bigIntAmountFormatter.format(amount: feeFiat.amount,
                                                                    fractionDigits: feeFiat.fractionLength,
                                                                    maximumFractionDigits: 2,
                                                                    symbol: tonRate.currency.symbol)
                feeFiatString = "≈\(feeFiatFormatted)"

            }
        }
        
        return SendTransactionViewModel.SendTokenModel(title: name,
                                        image: image,
                                        recipientAddress: recipientAddress,
                                        recipientName: recipientName,
                                        amountToken: "\(amountFormatted) \(token.tokenSymbol ?? "")",
                                        amountFiat: amountFiatString,
                                        feeTon: feeTonString,
                                        feeFiat: feeFiatString,
                                        comment: comment)
        
    }
}
