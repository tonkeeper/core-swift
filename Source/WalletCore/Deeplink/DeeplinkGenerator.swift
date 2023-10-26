//
//  DeeplinkGenerator.swift
//  
//
//  Created by Grigory on 4.7.23..
//

import Foundation
import TonSwift

public struct DeeplinkGenerator {
    public func generateTransferDeeplink(with string: String) throws -> TonDeeplink {
        let address = try Address.parse(string)
        return TonDeeplink.transfer(address: address)
    }
}
