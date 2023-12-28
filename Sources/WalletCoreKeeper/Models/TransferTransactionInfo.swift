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
        case nftTransfer
    }

    struct Recipient {
        let address: Address?
        let name: String?
    }
    
    struct Action {
        let type: ActionType
        let transferModel: TransferModel
        let recipient: Recipient
        let name: String
        let comment: String?
    }
    
    let actions: [Action]
    let fee: Int64
    let extra: Int64
    
    init(actions: [Action], fee: Int64, extra: Int64) {
        self.actions = actions
        self.fee = fee
        self.extra = extra
    }
    
    init(accountEvent: Components.Schemas.AccountEvent,
         risk: Components.Schemas.Risk,
         transaction: Components.Schemas.Transaction) {
        // TBD: When tonapi v2 will be fixed and in action will be correct jetton information - remove getting jetton info from Risk
        let actions = accountEvent.actions.compactMap { eventAction -> Action? in
            let type: ActionType
            let transferModel: TransferModel
            let recipient: Recipient
            let name: String
            let comment: String?
            
            if let tonTransferAction = eventAction.TonTransfer {
                type = .tonTransfer
                let amount = BigInt(integerLiteral: tonTransferAction.amount)
                transferModel = .token(TokenTransferModel(transferItem: .ton(isMax: false), amount: amount))
                recipient = Recipient(address: try? Address.parse(tonTransferAction.recipient.address),
                                      name: tonTransferAction.recipient.name)
                name = eventAction.simple_preview.name
                comment = tonTransferAction.comment
            } else if let jettonTransferAction = eventAction.JettonTransfer,
                      let riskJettonPreview = risk.jettons.first?.jetton,
                      let tokenInfo = try? TokenInfo(jettonPreview: riskJettonPreview),
                      let tokenWalletAddress = try? Address.parse(jettonTransferAction.recipients_wallet)  {
                type = .jettonTransfer
                let amount = BigInt(stringLiteral: jettonTransferAction.amount)
                transferModel = .token(
                    TokenTransferModel(
                        transferItem: .token(
                            tokenWalletAddress: tokenWalletAddress,
                            tokenInfo: tokenInfo),
                        amount: amount)
                )
                recipient = Recipient(address: try? Address.parse(jettonTransferAction.recipient?.address ?? ""),
                                      name: jettonTransferAction.recipient?.name)
                name = eventAction.simple_preview.name
                comment = jettonTransferAction.comment
            } else if let nftItemTransfer = eventAction.NftItemTransfer,
                      let nftAddress = try? Address.parse(nftItemTransfer.nft),
                      let recipientAccountAddress = nftItemTransfer.recipient {
                type = .nftTransfer
                transferModel = .nft(nftAddress: nftAddress)
                recipient = Recipient(address: try? Address.parse(recipientAccountAddress.address),
                                      name: recipientAccountAddress.name)
                name = eventAction.simple_preview.name
                comment = nftItemTransfer.comment
            } else {
                return nil
            }
            
            return Action(type: type,
                          transferModel: transferModel,
                          recipient: recipient,
                          name: name,
                          comment: comment)
        }
        
        self.actions = actions
        self.fee = transaction.total_fees
        self.extra = accountEvent.extra
    }
}
