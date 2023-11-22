//
//  TransferSignController.swift
//
//
//  Created by Grigory Serebryanyy on 22.11.2023.
//

import Foundation
import WalletCoreCore
import TonSwift

public enum TransferSignControllerError: Swift.Error {
    case failedToGetWalletPrivateKey
    case failedToSignTransfer
}

public protocol TransferSignController {
    func signTransfer(wallet: Wallet, boc: String) throws -> String
}

final class TransferSignControllerImplementation: TransferSignController {
    private let walletProvider: WalletProvider
    
    init(walletProvider: WalletProvider) {
        self.walletProvider = walletProvider
    }
    
    func signTransfer(wallet: Wallet, boc: String) throws -> String {
        let privateKey: TonSwift.PrivateKey
        do {
            privateKey = try walletProvider.getWalletPrivateKey(wallet)
        } catch {
            throw TransferSignControllerError.failedToGetWalletPrivateKey
        }
        
        do {
            let externalMessageCell = try Cell.fromBase64(src: boc)
            let externalMessageSlice = try externalMessageCell.toSlice()
            let externalMessage: Message = try externalMessageSlice.loadType()
            
            let transferCellSlice = try externalMessage.body.toSlice()
            try transferCellSlice.skip(64 * 8)
            let signingMessage: Builder = try transferCellSlice.loadType()
            
            let transfer = WalletTransfer(signingMessage: signingMessage)
            let signedTransfer = try transfer.signMessage(signer: WalletTransferSecretKeySigner(secretKey: privateKey.data))
            let signedExternalMessage = Message.external(to: try wallet.address,
                                                         stateInit: nil,
                                                         body: signedTransfer)
            return try Builder().store(signedExternalMessage).endCell().toBoc().base64EncodedString()
        } catch {
            throw TransferSignControllerError.failedToSignTransfer
        }
    }
}
