//
//  Action.swift
//  
//
//  Created by Grigory on 3.8.23..
//

import Foundation
import TonSwift
import BigInt

struct Action {
    let type: ActionType
    let status: Status
    let preview: SimplePreview
    
    struct SimplePreview {
        let name: String
        let description: String
        let image: URL?
        let value: String?
        let valueImage: URL?
        let accounts: [WalletAccount]
    }
    
    enum ActionType {
        case tonTransfer(TonTransfer)
        case contractDeploy(ContractDeploy)
        case jettonTransfer(JettonTransfer)
        case nftItemTransfer(NFTItemTransfer)
        case subscribe(Subscription)
        case unsubscribe(Unsubscription)
        case auctionBid(AuctionBid)
        case nftPurchase(NFTPurchase)
        case depositStake(DepositStake)
        case recoverStake(RecoverStake)
        case jettonSwap(JettonSwap)
        case smartContractExec(SmartContractExec)
    }
    
    struct TonTransfer {
        let sender: WalletAccount
        let recipient: WalletAccount
        let amount: Int64
        let comment: String?
    }

    struct ContractDeploy {
        let address: Address
    }

    struct JettonTransfer {
        let sender: WalletAccount?
        let recipient: WalletAccount?
        let senderAddress: Address
        let recipientAddress: Address
        let amount: BigInt
        let tokenInfo: TokenInfo
        let comment: String?
    }

    struct NFTItemTransfer {
        let sender: WalletAccount?
        let recipient: WalletAccount?
        let nftAddress: Address
        let comment: String?
        let payload: String?
    }

    struct Subscription {
        let subscriber: WalletAccount
        let subscriptionAddress: Address
        let beneficiary: WalletAccount
        let amount: Int64
        let isInitial: Bool
    }

    struct Unsubscription {
        let subscriber: WalletAccount
        let subscriptionAddress: Address
        let beneficiary: WalletAccount
    }

    struct AuctionBid {
        let auctionType: String
        let collectible: Collectible?
        let bidder: WalletAccount
        let auction: WalletAccount
    }

    struct NFTPurchase {
        let auctionType: String
        let collectible: Collectible
        let seller: WalletAccount
        let buyer: WalletAccount
    }

    struct DepositStake {
        let amount: Int64
        let staker: WalletAccount
    }

    struct RecoverStake {
        let amount: Int64
        let staker: WalletAccount
    }

    struct JettonSwap {
        let dex: String
        let amountIn: BigInt
        let amountOut: BigInt
        let user: WalletAccount
        let router: WalletAccount
        let tokenWalletIn: Address
        let tokenWalletOut: Address
        let tokenInfoIn: TokenInfo
        let tokenInfoOut: TokenInfo
    }

    struct SmartContractExec {
        let executor: WalletAccount
        let contract: WalletAccount
        let tonAttached: Int64
        let operation: String
        let payload: String?
    }
}
