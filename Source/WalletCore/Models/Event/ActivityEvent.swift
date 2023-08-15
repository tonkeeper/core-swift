//
//  ActivityEvent.swift
//  
//
//  Created by Grigory on 3.8.23..
//

import Foundation
import TonAPI
import TonSwift
import BigInt

struct ActivityEvent {
    let eventId: String
    let timestamp: TimeInterval
    let account: WalletAccount
    let isScam: Bool
    let isInProgress: Bool
    let fee: Int64
    let actions: [Action]
}

extension ActivityEvent {
    init(accountEvent: AccountEvent) throws {
        self.eventId = accountEvent.eventId
        self.timestamp = TimeInterval(accountEvent.timestamp)
        self.account = try WalletAccount(accountAddress: accountEvent.account)
        self.isScam = accountEvent.isScam
        self.isInProgress = accountEvent.isInProgress
        self.fee = accountEvent.extra
        self.actions = accountEvent.actions.compactMap { action in
            do {
                let actionType: Action.ActionType
                if let tonTransfer = action.tonTransfer {
                    actionType = .tonTransfer(try .init(tonTransfer: tonTransfer))
                } else if let jettonTransfer = action.jettonTransfer {
                    actionType = .jettonTransfer(try .init(jettonTransfer: jettonTransfer))
                } else if let contractDeploy = action.contractDeploy {
                    actionType = .contractDeploy(try .init(contractDeploy: contractDeploy))
                } else if let nftItemTransfer = action.nftItemTransfer {
                    actionType = .nftItemTransfer(try .init(nftItemTransfer: nftItemTransfer))
                } else if let subscribe = action.subscribe {
                    actionType = .subscribe(try .init(subscription: subscribe))
                } else if let unsubscribe = action.unSubscribe {
                    actionType = .unsubscribe(try .init(unsubscription: unsubscribe))
                } else if let auctionBid = action.auctionBid {
                    actionType = .auctionBid(try .init(auctionBid: auctionBid))
                } else if let nftPurchase = action.nftPurchase {
                    actionType = .nftPurchase(try .init(nftPurchase: nftPurchase))
                } else if let depositStake = action.depositStake {
                    actionType = .depositStake(try .init(depositStake: depositStake))
                } else if let recoverStake = action.recoverStake {
                    actionType = .recoverStake(try .init(recoverStake: recoverStake))
                } else if let jettonSwap = action.jettonSwap {
                    actionType = .jettonSwap(try .init(jettonSwap: jettonSwap))
                } else if let smartContractExec = action.smartContractExec {
                    actionType = .smartContractExec(try .init(smartContractExec: smartContractExec))
                } else {
                    return nil
                }
                
                let status = Status(rawValue: action.status)
                return Action(type: actionType, status: status, preview: try .init(simplePreview: action.simplePreview))
            } catch {
                return nil
            }
        }
    }
}

