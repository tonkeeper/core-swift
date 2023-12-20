//
//  ActivityEvents.swift
//  
//
//  Created by Grigory on 4.8.23..
//

import Foundation
import TonSwift

struct ActivityEvents: LocalStorable, Codable {
    var key: String {
        address.toRaw()
    }
    
    typealias KeyType = String
    
    let address: Address
    let events: [AccountEvent]
    let startFrom: Int64
    let nextFrom: Int64
}
