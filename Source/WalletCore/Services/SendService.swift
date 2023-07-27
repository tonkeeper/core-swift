//
//  SendService.swift
//  
//
//  Created by Grigory on 7.7.23..
//

import Foundation
import TonAPI
import TonSwift
import BigInt

protocol SendService {
    func loadSeqno(address: Address) async throws -> UInt64
    func loadTransactionInfo(boc: String) async throws -> TransferTransactionInfo
    func sendTransaction(boc: String) async throws
}

final class SendServiceImplementation: SendService {
    private let api: API
    
    init(api: API) {
        self.api = api
    }
    
    func loadSeqno(address: Address) async throws -> UInt64 {
        let request = GetSeqnoRequest(accountId: address.toRaw())
        let response = try await api.send(request: request)
        return response.entity.seqno
    }
    
    func loadTransactionInfo(boc: String) async throws -> TransferTransactionInfo {
        let request = WalletEmulateRequest(boc: boc)
        let response = try await api.send(request: request)
        return TransferTransactionInfo(accountEvent: response.entity.event,
                                       transaction: response.entity.trace.transaction)
    }
    
    func sendTransaction(boc: String) async throws {
        let request = BlockchainMessageRequest(boc: boc)
        _ = try await api.send(request: request)
    }
}

private struct GetSeqnoRequest: APIRequest {
    typealias Entity = Seqno
    
    var request: TonAPI.Request {
        Request(
            path: path,
            method: .GET,
            headers: [],
            queryItems: queryItems,
            bodyParameter: [:]
        )
    }
    
    var path: String {
        "/v1/wallet/getSeqno"
    }
    
    var queryItems: [URLQueryItem] {
        [.init(name: "account", value: accountId)]
    }
    
    let accountId: String
    
    init(accountId: String) {
        self.accountId = accountId
    }
}

private struct Seqno: Codable {
    let seqno: UInt64
}

struct TransferTransactionInfo {
    enum ActionType: String {
        case tonTransfer = "TonTransfer"
        case jettonTransfer = "JettonTransfer"
    }
    
    enum Transfer {
        case ton
        case token(tokenInfo: TokenInfo)
    }
    
    struct Recipient {
        let address: Address?
        let name: String?
    }
    
    struct Action {
        let type: ActionType
        let transfer: Transfer
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
            let transfer: Transfer
            let amount: BigInt
            let recipient: Recipient
            let name: String
            let comment: String?
            
            if let tonTransferAction = eventAction.tonTransfer {
                type = .tonTransfer
                transfer = .ton
                amount = BigInt(integerLiteral: tonTransferAction.amount)
                recipient = Recipient(address: try? Address.parse(tonTransferAction.recipient.address),
                                      name: tonTransferAction.recipient.name)
                name = eventAction.simplePreview.name
                comment = tonTransferAction.comment
            } else if let jettonTransferAction = eventAction.jettonTransfer,
                      let tokenInfo = try? TokenInfo(jettonPreview: jettonTransferAction.jetton){
                type = .jettonTransfer
                transfer = .token(tokenInfo: tokenInfo)
                amount = BigInt(stringLiteral: jettonTransferAction.amount)
                recipient = Recipient(address: try? Address.parse(jettonTransferAction.recipient?.address ?? ""),
                                      name: jettonTransferAction.recipient?.name)
                name = eventAction.simplePreview.name
                comment = jettonTransferAction.comment
            } else {
                return nil
            }
            
            return Action(type: type,
                          transfer: transfer,
                          amount: amount,
                          recipient: recipient,
                          name: name,
                          comment: comment)
        }
        
        self.actions = actions
        self.fee = transaction.totalFees
    }
}
