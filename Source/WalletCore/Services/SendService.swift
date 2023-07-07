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
    func loadTransactionInfo(boc: String) async throws -> EstimateTx
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
    
    func loadTransactionInfo(boc: String) async throws -> EstimateTx {
        let request = EstimateTxRequest(boc: boc)
        let response = try await api.send(request: request)
        return response.entity
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

private struct EstimateTxRequest: APIRequest {
    typealias Entity = EstimateTx
    
    var request: TonAPI.Request {
        Request(
            path: path,
            method: .POST,
            headers: [],
            queryItems: [],
            bodyParameter: ["boc": boc]
        )
    }
    
    var path: String {
        "/v1/send/estimateTx"
    }
    
    let boc: String
    
    init(boc: String) {
        self.boc = boc
    }
}

struct EstimateTx: Codable {
    enum ActionType: String {
        case tonTransfer = "TonTransfer"
    }
    
    struct Action {
        let type: ActionType
        let amount: BigInt
        let recipient: Address
        let name: String
    }
    
    let actions: [Action]
    let fee: Int64

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        var actionsContainer = try container.nestedUnkeyedContainer(forKey: "actions")
        
        var actions = [Action]()
        while !actionsContainer.isAtEnd {
            let actionContainer = try actionsContainer.nestedContainer(keyedBy: StringCodingKey.self)
            
            let type = try actionContainer.decode(String.self, forKey: "type")
            
            let tonTransfer = try actionContainer.nestedContainer(keyedBy: StringCodingKey.self, forKey: .init(string: type))
            let amount = try tonTransfer.decode(Int64.self, forKey: "amount")
            let recipient = try tonTransfer.nestedContainer(keyedBy: StringCodingKey.self, forKey: "recipient")
            let recipientAddress = try recipient.decode(String.self, forKey: "address")
            
            let preview = try actionContainer.nestedContainer(keyedBy: StringCodingKey.self, forKey: "simple_preview")
            let name = try preview.decode(String.self, forKey: "name")
            
            guard let actionType = ActionType(rawValue: type),
                  let address = try? Address.parse(recipientAddress) else { continue }
            
            let action = Action(type: actionType,
                                amount: BigInt(amount),
                                recipient: address,
                                name: name)
            actions.append(action)
        }
        
        let fee = try container.nestedContainer(keyedBy: StringCodingKey.self, forKey: "fee")
        let total = try fee.decode(Int64.self, forKey: "total")
        
        self.actions = actions
        self.fee = total
    }
    
    func encode(to encoder: Encoder) throws {}
}

struct StringCodingKey: CodingKey, ExpressibleByStringLiteral {
    private let string: String
    private var int: Int?

    var stringValue: String { return string }

    init(string: String) {
        self.string = string
    }

    init?(stringValue: String) {
        self.string = stringValue
    }

    var intValue: Int? { return int }

    init?(intValue: Int) {
        self.string = String(describing: intValue)
        self.int = intValue
    }

    init(stringLiteral value: String) {
        self.string = value
    }
}
