//
//  Rates.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation

struct Rates: Codable, LocalStorable {
    struct Rate: Codable {
        let currency: Currency
        let rate: Decimal
    }

    struct TokenRate: Codable {
        let tokenInfo: TokenInfo
        let rates: [Rate]
    }

    let ton: [Rate]
    let tokens: [TokenRate]
    
    static var fileName: String {
        String(describing: self)
    }
    
    var fileName: String {
        String(describing: type(of: self))
    }
}

