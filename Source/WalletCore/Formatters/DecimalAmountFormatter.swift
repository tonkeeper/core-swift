//
//  DecimalAmountFormatter.swift
//  
//
//  Created by Grigory on 2.7.23..
//

import Foundation
import BigInt

struct DecimalAmountFormatter {
    private let numberFormatter: NumberFormatter
    
    init(numberFormatter: NumberFormatter) {
        self.numberFormatter = numberFormatter
    }
    
    func format(amount: Decimal, symbol: String?, maximumFractionDigits: Int? = nil) -> String {
        let formatterMaximumFractionDigits: Int
        if let maximumFractionDigits = maximumFractionDigits {
            formatterMaximumFractionDigits = maximumFractionDigits
        } else {
            formatterMaximumFractionDigits = calculateFractionalDigitsCount(amount: amount, maximumNotZeroFractionalCount: 2)
        }
        let formatFractional = String(repeating: "#", count: formatterMaximumFractionDigits)
        let decimalNumberAmount = NSDecimalNumber(decimal: amount)
        numberFormatter.currencySymbol = symbol
        numberFormatter.positiveFormat = "¤ #,##0.\(formatFractional)"
        numberFormatter.roundingMode = .down
        return numberFormatter.string(from: decimalNumberAmount) ?? ""
    }
}

private extension DecimalAmountFormatter {
    func calculateFractionalDigitsCount(amount: Decimal,
                                        maximumNotZeroFractionalCount: Int) -> Int {
        let amountNumber = NSDecimalNumber(decimal: amount)
        let amountFractionalLength = max(Int16(-amount.exponent), 0)
        let amountFractional = amountNumber
            .subtracting(NSDecimalNumber(integerLiteral: amountNumber.intValue))
            .multiplying(byPowerOf10: amountFractionalLength)
        let notZeroFractionalCount = String(amountFractional.intValue).count
        let formatterFractinalDigitsCount = Int(amountFractionalLength) - notZeroFractionalCount + min(maximumNotZeroFractionalCount, notZeroFractionalCount)
        return formatterFractinalDigitsCount
    }
}
