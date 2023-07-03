//
//  RateConverter.swift
//  
//
//  Created by Grigory on 2.7.23..
//

import Foundation
import BigInt

struct RateConverter {
    func convert(amount: Int64,
                 amountFractionLength: Int,
                 rate: Rates.Rate) -> (amount: BigInt, fractionLength: Int) {
        let stringAmount = String(amount)
        let bigIntAmount = BigInt(stringLiteral: stringAmount)
        return convert(
            amount: bigIntAmount,
            amountFractionLength: amountFractionLength,
            rate: rate)
    }
    
    func convert(amount: BigInt,
                 amountFractionLength: Int,
                 rate: Rates.Rate) -> (amount: BigInt, fractionLength: Int) {
        let rateFractionLength = max(Int16(-rate.rate.exponent), 0)
        let ratePlain = NSDecimalNumber(decimal: rate.rate)
            .multiplying(byPowerOf10: rateFractionLength)
        let rateBigInt = BigInt(stringLiteral: ratePlain.stringValue)
        
        let converted = amount * rateBigInt
        let fractionLength = Int(rateFractionLength) + amountFractionLength
        return (amount: converted, fractionLength: fractionLength)
    }
}
