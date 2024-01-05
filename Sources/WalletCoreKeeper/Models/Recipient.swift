//
//  Recipient.swift
//  
//
//  Created by Grigory on 1.8.23..
//

import Foundation
import TonSwift

public struct Recipient {
    public enum RecipientAddress {
        case friendly(FriendlyAddress)
        case address(Address)
        
        public var address: Address {
            switch self {
            case .friendly(let friendlyAddress):
                return friendlyAddress.address
            case .address(let address):
                return address
            }
        }
        
        public var isBounceable: Bool {
            switch self {
            case .friendly(let friendlyAddress):
                return friendlyAddress.isBounceable
            case .address:
                return true
            }
        }
        
        public func toString() -> String {
            switch self {
            case .friendly(let friendlyAddress):
                return friendlyAddress.toString()
            case .address(let address):
                return address.toRaw()
            }
        }
        
        public init(string: String) throws {
            if let friendlyAddress = try? FriendlyAddress(string: string) {
                self = .friendly(friendlyAddress)
                return
            }
            self = .address(try Address.parse(string))
        }
    }
    
    public let address: RecipientAddress
    public let domain: String?
    
    public init(address: RecipientAddress,
                domain: String?) {
        self.address = address
        self.domain = domain
    }
    
    public var shortAddress: String {
        switch address {
        case .friendly(let friendlyAddress):
            return friendlyAddress.toShort()
        case .address(let address):
            return address.toShortRawString()
        }
    }
}
