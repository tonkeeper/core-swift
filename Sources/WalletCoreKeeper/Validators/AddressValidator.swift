//
//  AddressValidator.swift
//  
//
//  Created by Grigory on 6.7.23..
//

import Foundation
import TonSwift

public struct AddressValidator {
    public func validateAddress(_ address: String) -> Bool {
        let result: Bool
        do {
            _ = try Address.parse(address)
            result = true
        } catch {
            result = false
        }
         return result
    }
}
