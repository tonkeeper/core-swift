//
//  Balance.swift
//  
//
//  Created by Grigory on 1.7.23..
//

import Foundation
import TonSwift
import BigInt

struct WalletBalance: Codable, LocalStorable {
    let walletAddress: Address
    let tonBalance: TonBalance
    let tokensBalance: [TokenBalance]
    let previousRevisionsBalances: [TonBalance]
    let collectibles: [Collectible]
    
    var fileName: String {
        return walletAddress.toString()
    }
    
    static var fileName: String {
        ""
    }
}

struct TonBalance: Codable {
    let walletAddress: Address
    let amount: TonAmount
}

struct TokenBalance: Codable {
    let walletAddress: Address
    let amount: TokenAmount
}

struct TonAmount: Codable {
    private(set) var tonInfo = TonInfo()
    let quantity: Int64
}

struct TokenAmount: Codable {
    let tokenInfo: TokenInfo
    let quantity: BigInt
}

struct TonInfo: Codable {
    private(set) var name = "Toncoin"
    private(set) var symbol = "TON"
    private(set) var fractionDigits = 9
}

struct TokenInfo: Codable, Equatable {
    var address: Address
    var fractionDigits: Int
    var name: String
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

struct Collectible: Codable {
    let address: Address
    let name: String?
    let imageURL: URL?
    let description: String?
    let collection: Collection?
    
    struct Marketplace {
        let name: String
        let url: URL?
    }
    
    enum Trust {
        struct Approval {
            let name: String
        }
        case approvedBy([Approval])
    }
}

struct Collection: Codable {
    let address: Address
    let name: String?
}
