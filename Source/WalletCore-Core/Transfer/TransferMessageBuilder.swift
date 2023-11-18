//
//  TransferMessageBuilder.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation
import TonSwift
import BigInt

struct TonTransferMessageBuilder {
    private init() {}
    static func sendTonTransfer(wallet: Wallet,
                                seqno: UInt64,
                                value: BigInt,
                                recipientAddress: Address,
                                comment: String?) throws -> WalletTransfer {
        return try ExternalMessageTransferBuilder.externalMessageTransfer(
            wallet: wallet,
            sender: try wallet.address,
            seqno: seqno) { _ in
                let internalMessage: MessageRelaxed
                if let comment = comment {
                    internalMessage = try MessageRelaxed.internal(to: recipientAddress,
                                                                  value: value.magnitude,
                                                                  textPayload: comment)
                } else {
                    internalMessage = MessageRelaxed.internal(to: recipientAddress,
                                                              value: value.magnitude)
                }
                return [internalMessage]
                
            }
    }
}

struct TonConnectTransferMessageBuilder {
    private init() {}
    
    struct Payload {
        let value: BigInt
        let recipientAddress: Address
        let stateInit: String?
        let payload: String?
    }
    
    static func sendTonConnectTransfer(wallet: Wallet,
                                       seqno: UInt64,
                                       payloads: [Payload],
                                       sender: Address? = nil) throws -> WalletTransfer {
        let messages = try payloads.map { payload in
            var stateInit: StateInit?
            if let stateInitString = payload.stateInit {
                stateInit = try StateInit.loadFrom(
                    slice: try Cell
                        .fromBase64(src: stateInitString)
                        .toSlice()
                )
            }
            var body: Cell = .empty
            if let messagePayload = payload.payload {
                body = try Cell.fromBase64(src: messagePayload)
            }
            return MessageRelaxed.internal(
                to: payload.recipientAddress,
                value: payload.value.magnitude,
                stateInit: stateInit,
                body: body)
        }
        return try ExternalMessageTransferBuilder
            .externalMessageTransfer(
                wallet: wallet,
                sender: sender ?? (try wallet.address),
                seqno: seqno) { sender in
                    messages
                }
    }
}

struct TokenTransferMessageBuilder {
    private init() {}
    static func sendTokenTransfer(wallet: Wallet,
                                  seqno: UInt64,
                                  tokenAddress: Address,
                                  value: BigInt,
                                  recipientAddress: Address,
                                  comment: String?) throws -> WalletTransfer {
        return try ExternalMessageTransferBuilder
            .externalMessageTransfer(
                wallet: wallet,
                sender: try wallet.address,
                seqno: seqno) { sender in
                    let internalMessage = try JettonTransferMessage.internalMessage(
                        jettonAddress: tokenAddress,
                        amount: value,
                        to: recipientAddress,
                        from: sender,
                        comment: comment
                    )
                    return [internalMessage]
                }
    }
}

struct NFTTransferMessageBuilder {
    private init() {}
    static func sendNFTTransfer(wallet: Wallet,
                                seqno: UInt64,
                                nftAddress: Address,
                                recipientAddress: Address,
                                transferAmount: BigUInt) throws -> WalletTransfer {
        return try ExternalMessageTransferBuilder
            .externalMessageTransfer(
                wallet: wallet,
                sender: try wallet.address,
                seqno: seqno) { sender in
                    let internalMessage = try NFTTransferMessage.internalMessage(
                        nftAddress: nftAddress,
                        nftTransferAmount: transferAmount,
                        to: recipientAddress,
                        from: sender,
                        forwardPayload: nil)
                    return [internalMessage]
                }
    }
}

struct ExternalMessageTransferBuilder {
    private init() {}
    static func externalMessageTransfer(wallet: Wallet,
                                        sender: Address,
                                        seqno: UInt64,
                                        internalMessages: (_ sender: Address) throws -> [MessageRelaxed]) throws -> WalletTransfer {
        let internalMessages = try internalMessages(sender)
        let transferData = WalletTransferData(
            seqno: seqno,
            messages: internalMessages,
            sendMode: .walletDefault(),
            timeout: nil)
        let contract = try wallet.contract
        return try contract.createTransfer(args: transferData)
    }
}
