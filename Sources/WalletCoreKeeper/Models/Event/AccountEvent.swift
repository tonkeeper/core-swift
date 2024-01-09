//
//  AccountEvent.swift
//  
//
//  Created by Grigory on 3.8.23..
//

import Foundation
import TonAPI
import TonSwift
import BigInt

struct AccountEvent: Codable {
    let eventId: String
    let timestamp: TimeInterval
    let account: WalletAccount
    let isScam: Bool
    let isInProgress: Bool
    let fee: Int64
    let actions: [Action]
}

extension AccountEvent {
    init(accountEvent: Components.Schemas.AccountEvent) throws {
        self.eventId = accountEvent.event_id
        self.timestamp = TimeInterval(accountEvent.timestamp)
        self.account = try WalletAccount(accountAddress: accountEvent.account)
        self.isScam = accountEvent.is_scam
        self.isInProgress = accountEvent.in_progress
        self.fee = accountEvent.extra
        self.actions = accountEvent.actions.compactMap { action -> Action? in
            do {
                let actionType: Action.ActionType
                if let tonTransfer = action.TonTransfer {
                    actionType = .tonTransfer(try .init(tonTransfer: tonTransfer))
                } else if let jettonTransfer = action.JettonTransfer {
                    actionType = .jettonTransfer(try .init(jettonTransfer: jettonTransfer))
                } else if let contractDeploy = action.ContractDeploy {
                    actionType = .contractDeploy(try .init(contractDeploy: contractDeploy))
                } else if let nftItemTransfer = action.NftItemTransfer {
                    actionType = .nftItemTransfer(try .init(nftItemTransfer: nftItemTransfer))
                } else if let subscribe = action.Subscribe {
                    actionType = .subscribe(try .init(subscription: subscribe))
                } else if let unsubscribe = action.UnSubscribe {
                    actionType = .unsubscribe(try .init(unsubscription: unsubscribe))
                } else if let auctionBid = action.AuctionBid {
                    actionType = .auctionBid(try .init(auctionBid: auctionBid))
                } else if let nftPurchase = action.NftPurchase {
                    actionType = .nftPurchase(try .init(nftPurchase: nftPurchase))
                } else if let depositStake = action.DepositStake {
                    actionType = .depositStake(try .init(depositStake: depositStake))
                } else if let withdrawStake = action.WithdrawStake {
                    actionType = .withdrawStake(try .init(withdrawStake: withdrawStake))
                } else if let withdrawStakeRequest = action.WithdrawStakeRequest {
                    actionType = .withdrawStakeRequest(try .init(withdrawStakeRequest: withdrawStakeRequest))
                } else if let jettonSwap = action.JettonSwap {
                    actionType = .jettonSwap(try .init(jettonSwap: jettonSwap))
                } else if let jettonMint = action.JettonMint {
                    actionType = .jettonMint(try .init(jettonMint: jettonMint))
                } else if let jettonBurn = action.JettonBurn {
                    actionType = .jettonBurn(try .init(jettonBurn: jettonBurn))
                } else if let smartContractExec = action.SmartContractExec {
                    actionType = .smartContractExec(try .init(smartContractExec: smartContractExec))
                } else if let domainRenew = action.DomainRenew {
                    actionType = .domainRenew(try .init(domainRenew: domainRenew))
                } else {
                    actionType = .unknown
                }
                
                let status = Status(rawValue: action.status.rawValue)
                return Action(type: actionType, status: status, preview: try .init(simplePreview: action.simple_preview))
            } catch {
                return nil
            }
        }
    }
}

