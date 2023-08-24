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
    
    typealias KeyType = String
    
    var key: String {
        walletAddress.toString()
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

public struct TokenInfo: Codable, Equatable {
    public var address: Address
    public var fractionDigits: Int
    public var name: String
    public var symbol: String?
    public var description: String?
    public var imageURL: URL?
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.address == rhs.address
    }
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
    let owner: WalletAccount?
    let name: String?
    let imageURL: URL?
    let preview: Preview
    let description: String?
    let attributes: [Attribute]
    let collection: Collection?
    let dns: String?
    
    struct Marketplace {
        let name: String
        let url: URL?
    }
    
    struct Attribute: Codable {
        let key: String
        let value: String
    }
    
    enum Trust {
        struct Approval {
            let name: String
        }
        case approvedBy([Approval])
    }
    
    struct Preview: Codable {
        let size5: URL?
        let size100: URL?
        let size500: URL?
        let size1500: URL?
    }
}

struct Collection: Codable {
    let address: Address
    let name: String?
    let description: String?
}
