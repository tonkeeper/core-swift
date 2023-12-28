//
//  ItemTransferModel.swift
//  
//
//  Created by Grigory on 28.7.23..
//

import Foundation
import TonSwift
import BigInt

public enum TransferModel {
    case token(TokenTransferModel)
    case nft(nftAddress: Address)
}

public struct TokenTransferModel {
    public enum TransferItem {
        case ton(isMax: Bool)
        case token(tokenWalletAddress: Address, tokenInfo: TokenInfo)
    }
    
    public let transferItem: TransferItem
    public let amount: BigInt
}
