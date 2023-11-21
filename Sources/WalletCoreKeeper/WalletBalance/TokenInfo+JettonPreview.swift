//
//  TokenInfo+JettonPreview.swift
//  
//
//  Created by Grigory on 12.7.23..
//

import Foundation
import TonAPI
import TonSwift

extension TokenInfo {
    init(jettonPreview: Components.Schemas.JettonPreview) throws {
        let tokenAddress = try Address.parse(jettonPreview.address)
        address = tokenAddress
        fractionDigits = jettonPreview.decimals
        name = jettonPreview.name
        symbol = jettonPreview.symbol
        imageURL = URL(string: jettonPreview.image)
    }
}
