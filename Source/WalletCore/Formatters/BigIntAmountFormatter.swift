//
//  TokenAmountFormatter.swift
//  
//
//  Created by Grigory on 1.7.23..
//

import Foundation
import BigInt

struct BigIntAmountFormatter {
    
    enum Error: Swift.Error {
        case invalidInput(_ input: String)
    }
    
    func format(amount: BigInt,
                fractionDigits: Int,
                maximumFractionDigits: Int,
                symbol: String?) -> String {
        let symbolString = symbol ?? ""
        var initialString = amount.description
        if initialString.count < fractionDigits {
            initialString = String(repeating: "0", count: fractionDigits - initialString.count) + initialString
        }
        let fractional = String(initialString.suffix(fractionDigits))
        let fractionalLength = min(fractionDigits, maximumFractionDigits)
        let fractionalResult = String(fractional[fractional.startIndex..<fractional.index(fractional.startIndex, offsetBy: fractionalLength)])
            .replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
        let integer = String(initialString.prefix(initialString.count - fractional.count))
        let separatedInteger = groups(string: integer.isEmpty ? "0" : integer, size: .groupSize).joined(separator: .groupSeparator)
        var result = symbolString + separatedInteger
        if fractionalResult.count > 0 {
            result += (.fractionalSeparator ?? ".") + fractionalResult
        }
        return result
    }
    
    func bigInt(string: String, targetFractionalDigits: Int) throws -> (amount: BigInt, fractionalDigits: Int) {
        guard !string.isEmpty else { throw Error.invalidInput(string) }
        let fractionalSeparator: String = .fractionalSeparator ?? ""
        let components = string.components(separatedBy: fractionalSeparator)
        guard components.count < 3 else { throw Error.invalidInput(string) }
        
        var fractionalDigits = 0
        if components.count == 2 {
            let fractionalString = components[1]
            fractionalDigits = fractionalString.count
        }
        let zeroString = String(repeating: "0", count: max(0, targetFractionalDigits - fractionalDigits))
        let bigIntValue = BigInt(stringLiteral: components.joined() + zeroString)
        return (bigIntValue, targetFractionalDigits)
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
