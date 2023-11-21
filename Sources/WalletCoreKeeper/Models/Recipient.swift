//
//  Recipient.swift
//  
//
//  Created by Grigory on 1.8.23..
//

import Foundation
import TonSwift

public struct Recipient {
    public let address: Address
    public let domain: String?
    
    public init(address: Address, domain: String?) {
        self.address = address
        self.domain = domain
    }
}
