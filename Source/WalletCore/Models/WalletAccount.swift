//
//  WalletAccount.swift
//  
//
//  Created by Grigory on 3.8.23..
//

import Foundation
import TonSwift
import TonAPI

struct WalletAccount: Equatable {
    let address: Address
    let name: String?
    let isScam: Bool
}

extension WalletAccount {
    init(accountAddress: AccountAddress) throws {
        address = try Address.parse(accountAddress.address)
        name = accountAddress.name
        isScam = accountAddress.isScam
    }
}
