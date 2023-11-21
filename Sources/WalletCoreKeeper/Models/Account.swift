//
//  Account.swift
//  
//
//  Created by Grigory Serebryanyy on 25.10.2023.
//

import Foundation
import TonSwift

struct Account {
    let address: Address
    let balance: Int64
    let status: String
    let name: String?
    let icon: String?
    let isSuspended: Bool?
    let isWallet: Bool
}
