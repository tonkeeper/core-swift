//
//  SendService.swift
//  
//
//  Created by Grigory on 7.7.23..
//

import Foundation
import TonAPI
import TonSwift

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
                                       risk: response.entity.risk,
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
