//
//  AmountFormatter.swift
//
//
//  Created by Grigory on 30.9.23..
//

import Foundation
import BigInt

struct AmountFormatter {
    private let bigIntFormatter: BigIntAmountFormatter
    
    init(bigIntFormatter: BigIntAmountFormatter) {
        self.bigIntFormatter = bigIntFormatter
    }
    
    func formatAmount(_ amount: BigInt,
                      fractionDigits: Int,
                      maximumFractionDigits: Int,
                      currency: Currency? = nil) -> String {
        var formatted = bigIntFormatter.format(
            amount: amount,
            fractionDigits: fractionDigits,
            maximumFractionDigits: maximumFractionDigits)
        if let currency = currency {
            let format: String
            if currency.symbolOnLeft {
                format = "\(currency.symbol) %@"
            } else {
                format = "%@ \(currency.symbol)"
            }
            formatted = String(format: format, formatted)
        }
        return formatted
    }
    
    func formatAmountWithoutFractionIfThousand(_ amount: BigInt,
                                               fractionDigits: Int,
                                               maximumFractionDigits: Int,
                                               currency: Currency? = nil) -> String {
        let isMoreThanThousand = isMoreThanThousand(amount: amount, fractionalDigits: fractionDigits)
        let maximumFractionDigits = isMoreThanThousand ? 0 : maximumFractionDigits
        return formatAmount(
            amount,
            fractionDigits: fractionDigits,
            maximumFractionDigits: maximumFractionDigits,
            currency: currency
        )
    }
}


private extension AmountFormatter {
    func isMoreThanThousand(amount: BigInt, fractionalDigits: Int) -> Bool {
        let amountString = amount.description
        let fullAmountString: String
        if amountString.count < fractionalDigits {
            fullAmountString = String(repeating: "0", count: fractionalDigits - amountString.count) + amountString
        } else {
            fullAmountString = amountString
        }
        let integerLength = fullAmountString.count - fractionalDigits
        return integerLength >= 4
    }
}
