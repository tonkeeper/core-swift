//
//  TokenAmountFormatter.swift
//  
//
//  Created by Grigory on 1.7.23..
//

import Foundation
import BigInt

struct BigIntAmountFormatter {
    func format(amount: BigInt,
                fractionDigits: Int,
                maximumFractionDigits: Int,
                symbol: String?) -> String {
        let symbolString = symbol ?? ""
        guard amount > 0 else { return symbolString + " 0"  }
        let initialString = amount.description
        let fractional = String(initialString.suffix(fractionDigits))
        let fractionalLength = min(fractionDigits, maximumFractionDigits)
        let fractionalResult = String(fractional[fractional.startIndex..<fractional.index(fractional.startIndex, offsetBy: fractionalLength)])
        let integer = String(initialString.prefix(initialString.count - fractional.count))
        let separatedInteger = groups(string: integer, size: .groupSize).joined(separator: .groupSeparator)
        return symbolString + separatedInteger + (.fractionalSeparator ?? ".") + fractionalResult
    }
}

private extension BigIntAmountFormatter {
    func groups(string: String, size: Int) -> [String] {
        guard string.count > size else { return [string] }
        let groupBoundaries = stride(from: 0, to: string.count, by: size) + [string.count]
        return (0..<groupBoundaries.count - 1)
            .map { groupBoundaries[$0]..<groupBoundaries[$0 + 1] }.reversed()
            .map {
                let leftIndex = string.index(string.endIndex, offsetBy: -$0.upperBound)
                let righIndex = string.index(string.endIndex, offsetBy: -$0.lowerBound)
                return String(string[leftIndex..<righIndex])
            }
    }
}

private extension Int {
    static let groupSize = 3
}

private extension String {
    static let groupSeparator = " "
    static var fractionalSeparator: String? {
        Locale.current.decimalSeparator
    }
}
