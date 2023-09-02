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
    case failedToSendTransaction
}

public protocol SendControllerDelegate: AnyObject {
    func sendControllerDidStartLoadInitialData(_ sendController: SendController)
    func sendController(_ sendController: SendController, didUpdate model: SendTransactionViewModel)
    func sendControllerFailed(_ sendController: SendController, error: SendControllerError)
}

public protocol SendController: AnyObject {
    var delegate: SendControllerDelegate? { get set }
    
    func prepareTransaction()
    func sendTransaction() async throws
}
