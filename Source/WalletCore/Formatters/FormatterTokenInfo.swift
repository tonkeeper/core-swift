//
//  FormatterTokenInfo.swift
//  
//
//  Created by Grigory on 12.7.23..
//

import Foundation

protocol FormatterTokenInfo {
    var tokenSymbol: String? { get }
    var fractionDigits: Int { get }
}

extension TonInfo: FormatterTokenInfo {
    var tokenSymbol: String? {
        symbol
    }
}

extension TokenInfo: FormatterTokenInfo {
    var tokenSymbol: String? {
        symbol
    }
}
