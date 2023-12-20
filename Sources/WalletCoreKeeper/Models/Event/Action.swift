//
//  Action.swift
//  
//
//  Created by Grigory on 3.8.23..
//

import Foundation
import TonSwift
import BigInt

struct Action: Codable {
    let type: ActionType
    let status: Status
    let preview: SimplePreview
    
    struct SimplePreview: Codable {
        let name: String
        let description: String
        let image: URL?
        let value: String?
        let valueImage: URL?
        let accounts: [WalletAccount]
    }
    
    enum ActionType: Codable {
        case tonTransfer(TonTransfer)
        case contractDeploy(ContractDeploy)
        case jettonTransfer(JettonTransfer)
        case nftItemTransfer(NFTItemTransfer)
        case subscribe(Subscription)
        case unsubscribe(Unsubscription)
        case auctionBid(AuctionBid)
        case nftPurchase(NFTPurchase)
        case depositStake(DepositStake)
        case withdrawStake(WithdrawStake)
        case withdrawStakeRequest(WithdrawStakeRequest)
        case jettonSwap(JettonSwap)
        case jettonMint(JettonMint)
        case jettonBurn(JettonBurn)
        case smartContractExec(SmartContractExec)
    }
    
    struct TonTransfer: Codable {
        let sender: WalletAccount
        let recipient: WalletAccount
        let amount: Int64
        let comment: String?
    }

    struct ContractDeploy: Codable {
        let address: Address
    }

    struct JettonTransfer: Codable {
        let sender: WalletAccount?
        let recipient: WalletAccount?
        let senderAddress: Address
        let recipientAddress: Address
        let amount: BigInt
        let tokenInfo: TokenInfo
        let comment: String?
    }

    struct NFTItemTransfer: Codable {
        let sender: WalletAccount?
        let recipient: WalletAccount?
        let nftAddress: Address
        let comment: String?
        let payload: String?
    }

    struct Subscription: Codable {
        let subscriber: WalletAccount
        let subscriptionAddress: Address
        let beneficiary: WalletAccount
        let amount: Int64
        let isInitial: Bool
    }

    struct Unsubscription: Codable {
        let subscriber: WalletAccount
        let subscriptionAddress: Address
        let beneficiary: WalletAccount
    }

    struct AuctionBid: Codable {
        let auctionType: String
        let collectible: Collectible?
        let bidder: WalletAccount
        let auction: WalletAccount
    }

    struct NFTPurchase: Codable {
        let auctionType: String
        let collectible: Collectible
        let seller: WalletAccount
        let buyer: WalletAccount
        let price: BigInt
    }

    struct DepositStake: Codable {
        let amount: Int64
        let staker: WalletAccount
        let pool: WalletAccount
    }
    
    struct WithdrawStake: Codable {
        let amount: Int64
        let staker: WalletAccount
        let pool: WalletAccount
    }

    struct WithdrawStakeRequest: Codable {
        let amount: Int64?
        let staker: WalletAccount
        let pool: WalletAccount
    }

    struct RecoverStake: Codable {
        let amount: Int64
        let staker: WalletAccount
    }

    struct JettonSwap: Codable {
        let dex: String
        let amountIn: BigInt
        let amountOut: BigInt
        let tonIn: Int64?
        let tonOut: Int64?
        let user: WalletAccount
        let router: WalletAccount
        let tokenInfoIn: TokenInfo?
        let tokenInfoOut: TokenInfo?
    }
    
    struct JettonMint: Codable {
        let recipient: WalletAccount
        let recipientsWallet: Address
        let amount: BigInt
        let tokenInfo: TokenInfo
    }
    
    struct JettonBurn: Codable {
        let sender: WalletAccount
        let senderWallet: Address
        let amount: BigInt
        let tokenInfo: TokenInfo
    }

    struct SmartContractExec: Codable {
        let executor: WalletAccount
        let contract: WalletAccount
        let tonAttached: Int64
        let operation: String
        let payload: String?
    }
}
