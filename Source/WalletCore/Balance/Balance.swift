//
//  Balance.swift
//  
//
//  Created by Grigory on 1.7.23..
//

import Foundation
import TonSwift
import BigInt

enum Balance {
    case ton(TonBalance)
    case token(TokenBalance)
    case app
}

struct TonBalance {
    let amount: TonAmount
}

struct TokenBalance {
    let amount: TokenAmount
}

struct TonAmount {
    let tonInfo: TonInfo
    let quantity: BigInt
}

struct TokenAmount {
    let tokenInfo: TokenInfo
    let quantity: BigInt
}

struct TonInfo {
    let name = "Toncoin"
    let symbol = "TON"
    let decimals = 9
}

struct TokenInfo {
    var address: Address
    var decimals: Int
    var name: String?
    var symbol: String?
    var description: String?
}

struct AppBalance {
    let appId: String
    
    let title: String?
    let subtitle: String?
    let iconURL: URL?
    let description: String?
    
    let value: AppValue?
    let subvalue: AppValue?
    
    let appURL: URL?
}

enum AppValue {
    case plain(String)
    case appAmount(AppAmount)
    case tokenAmount(AppTokenAmount)
}

struct AppAmount {
    let quantity: BigInt
    let decimals: Int
}

enum AppTokenAmount {
    case ton(TonBalance)
    case token(TokenBalance)
}
