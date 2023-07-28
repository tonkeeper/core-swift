//
//  TransferTransactionInfo.swift
//  
//
//  Created by Grigory on 28.7.23..
//

import Foundation
import TonAPI
import TonSwift
import BigInt

struct TransferTransactionInfo {
    enum ActionType {
        case tonTransfer
        case jettonTransfer
    }

    struct Recipient {
        let address: Address?
        let name: String?
    }
    
    struct Action {
        let type: ActionType
        let transferItem: ItemTransferModel.TransferItem
        let amount: BigInt
        let recipient: Recipient
        let name: String
        let comment: String?
    }
    
    let actions: [Action]
    let fee: Int64
    
    init(actions: [Action], fee: Int64) {
        self.actions = actions
        self.fee = fee
    }
    
    init(accountEvent: AccountEvent,
         transaction: Transaction) {
        let actions = accountEvent.actions.compactMap { eventAction -> Action? in
            let type: ActionType
            let transferItem: ItemTransferModel.TransferItem
            let amount: BigInt
            let recipient: Recipient
            let name: String
            let comment: String?
            
            if let tonTransferAction = eventAction.tonTransfer {
                type = .tonTransfer
                transferItem = .ton
                amount = BigInt(integerLiteral: tonTransferAction.amount)
                recipient = Recipient(address: try? Address.parse(tonTransferAction.recipient.address),
                                      name: tonTransferAction.recipient.name)
                name = eventAction.simplePreview.name
                comment = tonTransferAction.comment
            } else if let jettonTransferAction = eventAction.jettonTransfer,
                      let tokenInfo = try? TokenInfo(jettonPreview: jettonTransferAction.jetton),
                      let tokenWalletAddress = try? Address.parse(jettonTransferAction.recipientsWallet)  {
                type = .jettonTransfer
                transferItem = .token(tokenWalletAddress: tokenWalletAddress, tokenInfo: tokenInfo)
                amount = BigInt(stringLiteral: jettonTransferAction.amount)
                recipient = Recipient(address: try? Address.parse(jettonTransferAction.recipient?.address ?? ""),
                                      name: jettonTransferAction.recipient?.name)
                name = eventAction.simplePreview.name
                comment = jettonTransferAction.comment
            } else {
                return nil
            }
            
            return Action(type: type,
                          transferItem: transferItem,
                          amount: amount,
                          recipient: recipient,
                          name: name,
                          comment: comment)
        }
        
        self.actions = actions
        self.fee = transaction.totalFees
    }
}
