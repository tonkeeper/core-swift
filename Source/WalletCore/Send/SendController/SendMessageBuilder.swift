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
    private let mnemonicVault: KeychainMnemonicVault
    private let sendService: SendService
    
    init(walletProvider: WalletProvider, 
         mnemonicVault: KeychainMnemonicVault,
         sendService: SendService) {
        self.walletProvider = walletProvider
        self.mnemonicVault = mnemonicVault
        self.sendService = sendService
    }
    
    struct SendTonPayload {
        let value: BigInt
        let recipientAddress: Address
        let comment: String?
    }
    
    func sendTonTransactionsBoc(_ payloads: [SendTonPayload]) async throws -> String {
        let messages = try payloads.map { payload in
            let internalMessage: MessageRelaxed
            if let comment = payload.comment {
                internalMessage = try MessageRelaxed.internal(to: payload.recipientAddress,
                                                              value: payload.value.magnitude,
                                                              textPayload: comment)
            } else {
                internalMessage = MessageRelaxed.internal(to: payload.recipientAddress,
                                                          value: payload.value.magnitude)
            }
            return internalMessage
        }
        return try await externalMessageBoc(internalMessages: { _ in
            messages
        })
    }

    func sendTokenTransactionBoc(tokenAddress: String,
                                 value: BigInt,
                                 recipientAddress: Address,
                                 comment: String?) async throws -> String {
        return try await externalMessageBoc(internalMessages: { sender in
            let internalMessage = try JettonTransferMessage.internalMessage(
                jettonAddress: try Address.parse(tokenAddress),
                amount: value,
                to: recipientAddress,
                from: sender,
                comment: comment
            )
            return [internalMessage]
        })
    }
    
    func sendNFTEstimateBoc(nftAddress: Address,
                            recipientAddress: Address,
                            transferAmount: BigUInt) async throws -> String {
        return try await externalMessageBoc(internalMessages: { sender in
            let internalMessage = try NFTTransferMessage.internalMessage(
                nftAddress: nftAddress,
                nftTransferAmount: transferAmount,
                to: recipientAddress,
                from: sender,
                forwardPayload: nil)
            return [internalMessage]
        })
    }

    func externalMessageBoc(internalMessages: (_ sender: Address) throws -> [MessageRelaxed]) async throws -> String {
        let wallet = try walletProvider.activeWallet
        let walletPublicKey = try wallet.publicKey
        let contractBuilder = WalletContractBuilder()
        let contract = try contractBuilder.walletContract(with: walletPublicKey,
                                                          contractVersion: wallet.contractVersion)
        let mnemonic = try mnemonicVault.loadValue(key: wallet)
        let keyPair = try Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonic)
        
        let senderAddress = try contract.address()
        
        let internalMessages = try internalMessages(senderAddress)
        
        let seqno = try await sendService.loadSeqno(address: senderAddress)
        let transferData = WalletTransferData(
            seqno: seqno,
            secretKey: keyPair.privateKey.data,
            messages: internalMessages,
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
