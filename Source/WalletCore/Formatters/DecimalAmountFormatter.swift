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
    
    func format(amount: Decimal, symbol: String?) -> String {
        let decimalNumberAmount = NSDecimalNumber(decimal: amount)
        numberFormatter.currencySymbol = symbol
        numberFormatter.positiveFormat = "¤ #,##0.00"
        return numberFormatter.string(from: decimalNumberAmount) ?? ""
    }
}
