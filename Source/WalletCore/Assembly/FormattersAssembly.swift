//
//  FormattersAssembly.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation

final class FormattersAssembly {
    var shortNumberFormatter: NumberFormatter {
        NumberFormatter.shortNumberFormatter()
    }
    
    var decimalAmountFormatter: DecimalAmountFormatter {
        DecimalAmountFormatter(numberFormatter: shortNumberFormatter)
    }
    
    var intAmountFormatter: IntAmountFormatter {
        IntAmountFormatter(numberFormatter: shortNumberFormatter)
    }
    
    var bigIntAmountFormatter: BigIntAmountFormatter {
        BigIntAmountFormatter()
    }
    
    var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.init(identifier: "EN")
        return dateFormatter
    }
}
