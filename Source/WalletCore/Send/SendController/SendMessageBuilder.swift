//
//  SendMessageBuilder.swift
//
//
//  Created by Grigory on 30.8.23..
//

import Foundation
import TonSwift
import BigInt

struct SendMessageBuilder {
    private let walletProvider: WalletProvider
    private let keychainManager: KeychainManager
    private let keychainGroup: String
    private let sendService: SendService
    
    init(walletProvider: WalletProvider, 
         keychainManager: KeychainManager,
         keychainGroup: String,
         sendService: SendService) {
        self.walletProvider = walletProvider
        self.keychainManager = keychainManager
        self.keychainGroup = keychainGroup
        self.sendService = sendService
    }
    
    func sendTonTransactionBoc(value: BigInt,
                               recipientAddress: Address,
                               comment: String?) async throws -> String {
        return try await externalMessageBoc { sender in
            let internalMessage: MessageRelaxed
            if let comment = comment {
                internalMessage = try MessageRelaxed.internal(to: recipientAddress,
                                                              value: value.magnitude,
                                                              textPayload: comment)
            } else {
                internalMessage = MessageRelaxed.internal(to: recipientAddress,
                                                          value: value.magnitude)
            }
            return internalMessage
        }
    }
    
    func sendTokenTransactionBoc(tokenAddress: String,
                                 value: BigInt,
                                 recipientAddress: Address,
                                 comment: String?) async throws -> String {
        return try await externalMessageBoc { sender in
            let internalMessage = try JettonTransferMessage.internalMessage(jettonAddress: try Address.parse(tokenAddress),
                                                                            amount: value,
                                                                            to: recipientAddress,
                                                                            from: sender,
                                                                            comment: comment)
            return internalMessage
        }
    }
    
    func sendNFTEstimateBoc(nftAddress: Address,
                            recipientAddress: Address,
                            transferAmount: BigUInt) async throws -> String {
        return try await externalMessageBoc { sender in
            let internalMessage = try NFTTransferMessage.internalMessage(
                nftAddress: nftAddress,
                nftTransferAmount: transferAmount,
                to: recipientAddress,
                from: sender,
                forwardPayload: nil)
            return internalMessage
        }
    }

    func externalMessageBoc(internalMessage: (_ sender: Address) throws -> MessageRelaxed) async throws -> String {
        let wallet = try walletProvider.activeWallet
        let walletPublicKey = try wallet.publicKey
        let mnemonicVault = try KeychainMnemonicVault(
            keychainManager: keychainManager,
            walletID: wallet.identity.id(),
            keychainGroup: keychainGroup)
        let contractBuilder = WalletContractBuilder()
        let contract = try contractBuilder.walletContract(with: walletPublicKey,
                                                          contractVersion: wallet.contractVersion)
        let mnemonic = try mnemonicVault.loadValue(key: walletPublicKey)
        let keyPair = try Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonic)
        
        let senderAddress = try contract.address()
        
        let internalMessage = try internalMessage(senderAddress)
        
        let seqno = try await sendService.loadSeqno(address: senderAddress)
        let transferData = WalletTransferData(
            seqno: seqno,
            secretKey: keyPair.privateKey.data,
            messages: [internalMessage],
            sendMode: .walletDefault(),
            timeout: nil)
        let transferCell = try contract.createTransfer(args: transferData)
        let externalMessage = Message.external(to: senderAddress,
                                               stateInit: nil,
                                               body: transferCell)
        let cell = try Builder().store(externalMessage).endCell()
        return try cell.toBoc().base64EncodedString()
    }
}
