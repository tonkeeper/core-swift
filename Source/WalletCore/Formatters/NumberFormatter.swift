//
//  NumberFormatterBuilder.swift
//
//
//  Created by Grigory on 1.7.23..
//

import Foundation

extension NumberFormatter {
    static func shortNumberFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = " "
        formatter.groupingSize = 3
        formatter.usesGroupingSeparator = true
        formatter.decimalSeparator = Locale.current.decimalSeparator
        formatter.maximumFractionDigits = 2
        return formatter
    }
}
