//
//  SendTokenMapper.swift
//  
//
//  Created by Grigory on 11.7.23..
//

import Foundation
import TonSwift
import BigInt

struct SendTokenMapper {
    private let intAmountFormatter: IntAmountFormatter
    private let decimalAmountFormatter: DecimalAmountFormatter
    private let amountFormatter: AmountFormatter
    
    init(intAmountFormatter: IntAmountFormatter,
         decimalAmountFormatter: DecimalAmountFormatter,
         amountFormatter: AmountFormatter) {
        self.intAmountFormatter = intAmountFormatter
        self.decimalAmountFormatter = decimalAmountFormatter
        self.amountFormatter = amountFormatter
    }
    
    func mapTon(tonBalance: TonBalance) -> TokenListModel.TokenModel {
        let amount = intAmountFormatter.format(
            amount: tonBalance.amount.quantity,
            fractionDigits: tonBalance.amount.tonInfo.fractionDigits)
        return TokenListModel.TokenModel(icon: .ton,
                                         code: tonBalance.amount.tonInfo.symbol,
                                         amount: amount)
    }
    
    func mapToken(tokenBalance: TokenBalance) -> TokenListModel.TokenModel {
        let amount = amountFormatter.formatAmount(
            tokenBalance.amount.quantity,
            fractionDigits: tokenBalance.amount.tokenInfo.fractionDigits,
            maximumFractionDigits: 16
        )
        return TokenListModel.TokenModel(icon:.url(tokenBalance.amount.tokenInfo.imageURL),
                                         code: tokenBalance.amount.tokenInfo.symbol,
                                         amount: amount)
    }
}
