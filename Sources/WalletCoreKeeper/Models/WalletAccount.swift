//
//  WalletAccount.swift
//  
//
//  Created by Grigory on 3.8.23..
//

import Foundation
import TonSwift
import TonAPI

public struct WalletAccount: Equatable, Codable {
    let address: Address
    let name: String?
    let isScam: Bool
    let isWallet: Bool
}

extension WalletAccount {
    init(accountAddress: Components.Schemas.AccountAddress) throws {
        address = try Address.parse(accountAddress.address)
        name = accountAddress.name
        isScam = accountAddress.is_scam
        isWallet = accountAddress.is_wallet
    }
}
