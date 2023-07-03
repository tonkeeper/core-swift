//
//  IntAmountFormatter.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation

struct IntAmountFormatter {
    private let numberFormatter: NumberFormatter
    
    init(numberFormatter: NumberFormatter) {
        self.numberFormatter = numberFormatter
    }
    
    func format(amount: Int64,
                fractionDigits: Int) -> String {
        let decimalAmount = Decimal(amount)
        let decimalNumberAmount = NSDecimalNumber(decimal: decimalAmount)
        let divider = NSDecimalNumber(value: 1).multiplying(byPowerOf10: Int16(fractionDigits))
        let number = decimalNumberAmount.dividing(by: divider)
        return numberFormatter.string(from: number) ?? ""
    }
}
