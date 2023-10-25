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
        try await UInt64(api.getSeqno(address: address))
    }
    
    func loadTransactionInfo(boc: String) async throws -> TransferTransactionInfo {
        try await api
            .emulateMessageWallet(boc: boc)
    }
    
    func sendTransaction(boc: String) async throws {
        try await api
            .sendTransaction(boc: boc)
    }
}
