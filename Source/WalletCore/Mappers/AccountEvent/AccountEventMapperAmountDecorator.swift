//
//  AccountEventMapperAmountDecorator.swift
//
//
//  Created by Grigory Serebryanyy on 31.10.2023.
//

import Foundation
import BigInt

enum AccountEventActionAmountMapperActionType {
    case income
    case outcome
    case none
    
    var sign: String {
        switch self {
        case .income: return "\(String.Symbol.plus)\(String.Symbol.shortSpace)"
        case .outcome: return "\(String.Symbol.minus)\(String.Symbol.shortSpace)"
        case .none: return ""
        }
    }
}

protocol AccountEventActionAmountMapper {
    func mapAmount(amount: BigInt,
                   fractionDigits: Int,
                   maximumFractionDigits: Int,
                   type: AccountEventActionAmountMapperActionType,
                   currency: Currency?) -> String
    
    func mapAmount(amount: BigInt,
                   fractionDigits: Int,
                   maximumFractionDigits: Int,
                   type: AccountEventActionAmountMapperActionType,
                   symbol: String?) -> String
}

struct AmountAccountEventActionAmountMapper: AccountEventActionAmountMapper {
    private let amountFormatter: AmountFormatter
    
    init(amountFormatter: AmountFormatter) {
        self.amountFormatter = amountFormatter
    }
    
    func mapAmount(amount: BigInt,
                   fractionDigits: Int,
                   maximumFractionDigits: Int,
                   type: AccountEventActionAmountMapperActionType,
                   currency: Currency?) -> String {
        amountFormatter.formatAmount(
            amount,
            fractionDigits: fractionDigits,
            maximumFractionDigits: maximumFractionDigits,
            currency: currency)
    }
    
    func mapAmount(amount: BigInt,
                   fractionDigits: Int,
                   maximumFractionDigits: Int,
                   type: AccountEventActionAmountMapperActionType,
                   symbol: String?) -> String {
        amountFormatter.formatAmount(
            amount,
            fractionDigits: fractionDigits,
            maximumFractionDigits: maximumFractionDigits,
            symbol: symbol)
    }
}

struct SignedAmountAccountEventActionAmountMapper: AccountEventActionAmountMapper {
    let amountAccountEventActionAmountMapper: AccountEventActionAmountMapper
    
    init(amountAccountEventActionAmountMapper: AccountEventActionAmountMapper) {
        self.amountAccountEventActionAmountMapper = amountAccountEventActionAmountMapper
    }
    
    
    func mapAmount(amount: BigInt,
                   fractionDigits: Int, 
                   maximumFractionDigits: Int,
                   type: AccountEventActionAmountMapperActionType,
                   currency: Currency?) -> String {
        return type.sign + amountAccountEventActionAmountMapper
            .mapAmount(
                amount: amount,
                fractionDigits: fractionDigits,
                maximumFractionDigits: maximumFractionDigits,
                type: type,
                currency: currency
            )
    }
    
    func mapAmount(amount: BigInt,
                   fractionDigits: Int,
                   maximumFractionDigits: Int,
                   type: AccountEventActionAmountMapperActionType,
                   symbol: String?) -> String {
        return type.sign + amountAccountEventActionAmountMapper
            .mapAmount(
                amount: amount,
                fractionDigits: fractionDigits,
                maximumFractionDigits: maximumFractionDigits,
                type: type,
                symbol: symbol
            )
    }
}
