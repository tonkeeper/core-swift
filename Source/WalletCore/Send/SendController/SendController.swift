//
//  SendController.swift
//  
//
//  Created by Grigory on 6.7.23..
//

import Foundation
import TonSwift
import BigInt

public enum SendControllerError: Swift.Error {
    case failedToPrepareTransaction
    case failedToEmulateTransaction
}

public protocol SendController {
    func getInitialTransactionModel() -> SendTransactionViewModel
    func loadTransactionModel() async throws -> SendTransactionViewModel
    func sendTransaction() async throws
}
