//
//  SendController.swift
//  
//
//  Created by Grigory on 6.7.23..
//

import Foundation
import TonSwift
import BigInt

public final class SendController {
    
    public enum Error: Swift.Error {
        case failedToPrepareTransaction
        case failedToEmulateTransaction
    }
    
    private let walletProvider: WalletProvider
    private let keychainManager: KeychainManager
    private let sendService: SendService
    private let rateService: RatesService
    private let intAmountFormatter: IntAmountFormatter
    private let bigIntAmountFormatter: BigIntAmountFormatter
    
    init(walletProvider: WalletProvider,
         keychainManager: KeychainManager,
         sendService: SendService,
         rateService: RatesService,
         intAmountFormatter: IntAmountFormatter,
         bigIntAmountFormatter: BigIntAmountFormatter) {
        self.walletProvider = walletProvider
        self.keychainManager = keychainManager
        self.sendService = sendService
        self.rateService = rateService
        self.intAmountFormatter = intAmountFormatter
        self.bigIntAmountFormatter = bigIntAmountFormatter
    }
    
    public func initialSendTransactionModel(itemTransferModel: ItemTransferModel,
                                            recipient: Recipient,
                                            comment: String?) -> SendTransactionViewModel {
        let mapper = SendConfirmationMapper(bigIntAmountFormatter: bigIntAmountFormatter)
        
        let mapperRates: (tokenRates: Rates.Rate?, tonRates: Rates.Rate?)
        if let cachedRates = try? rateService.getRates() {
            mapperRates = getRates(itemTransferModel: itemTransferModel, rates: cachedRates)
        } else {
            mapperRates = (nil, nil)
        }
        
        let model = mapper.mapItemTransferModel(
            itemTransferModel,
            recipientAddress: recipient.address.shortString,
            recipientName: recipient.domain,
            fee: nil,
            comment: comment,
            rate: mapperRates.tonRates,
            tonRate: mapperRates.tonRates)
        return model
    }
    
    public func loadTransactionInformation(itemTransferModel: ItemTransferModel,
                                           recipient: Recipient,
                                           comment: String?) async throws -> SendTransactionViewModel {
        async let ratesTask = loadRates(itemTransferModel: itemTransferModel)
        async let transactionBocTask = prepareSendTransaction(itemTransferModel: itemTransferModel,
                                                              recipientAddress: recipient.address,
                                                              comment: comment)
        
        let mapperRates: (tokenRates: Rates.Rate?, tonRates: Rates.Rate?)
        if let loadedRates = try? await ratesTask {
            mapperRates = getRates(itemTransferModel: itemTransferModel, rates: loadedRates)
        } else {
            mapperRates = (nil, nil)
        }
        
        let transactionBoc = try await transactionBocTask
        let transactionInfo = try await sendService.loadTransactionInfo(boc: transactionBoc)
        let action = try getAction(transactionInfo: transactionInfo)
        let mapper = SendConfirmationMapper(bigIntAmountFormatter: bigIntAmountFormatter)
        let transactionModel = mapper.mapAction(action: action,
                                                fee: transactionInfo.fee,
                                                comment: action.comment,
                                                rate: mapperRates.tokenRates,
                                                tonRate: mapperRates.tonRates)
        return transactionModel
    }
    
    public func sendTransaction(itemTransferModel: ItemTransferModel,
                                recipient: Recipient,
                                comment: String?) async throws {
        let transactionBoc = try await prepareSendTransaction(
            itemTransferModel: itemTransferModel,
            recipientAddress: recipient.address,
            comment: comment
        )
        
        try await sendService.sendTransaction(boc: transactionBoc)
    }
}

private extension SendController {
    func prepareSendTransaction(itemTransferModel: ItemTransferModel,
                                recipientAddress: Address,
                                comment: String?) async throws -> String {
        switch itemTransferModel.transferItem {
        case .ton:
            return try await prepareSendTonTransaction(
                value: itemTransferModel.amount,
                recipientAddress: recipientAddress,
                comment: comment)
        case .token(let tokenAddress, _):
            return try await prepareSendTokenTransaction(
                tokenAddress: tokenAddress.toString(),
                value: itemTransferModel.amount,
                recipientAddress: recipientAddress,
                comment: comment)
        }
    }
    
    func prepareSendTonTransaction(value: BigInt,
                                   recipientAddress: Address,
                                   comment: String?) async throws -> String {
        return try await sendExternalMessage { sender in
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
    
    func prepareSendTokenTransaction(tokenAddress: String,
                                     value: BigInt,
                                     recipientAddress: Address,
                                     comment: String?) async throws -> String {
        return try await sendExternalMessage { sender in
            let internalMessage = try JettonTransferMessage.internalMessage(jettonAddress: try Address.parse(tokenAddress),
                                                                            amount: value,
                                                                            to: recipientAddress,
                                                                            from: sender,
                                                                            comment: comment)
            return internalMessage
        }
    }
    
    func sendExternalMessage(internalMessage: (_ sender: Address) throws -> MessageRelaxed) async throws -> String {
        let wallet = try walletProvider.activeWallet
        let walletPublicKey = try wallet.publicKey
        let mnemonicVault = try KeychainMnemonicVault(keychainManager: keychainManager, walletID: wallet.identity.id())
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
    
    func getAction(transactionInfo: TransferTransactionInfo) throws -> TransferTransactionInfo.Action {
        if let jettonTransferAction = transactionInfo.actions.first(where: { $0.type == .jettonTransfer }) {
            return jettonTransferAction
        }
        
        if let tonTransfer = transactionInfo.actions.last {
            return tonTransfer
        }
        
        throw Error.failedToEmulateTransaction
    }
    
    func getRates(itemTransferModel: ItemTransferModel, rates: Rates) -> (tokenRates: Rates.Rate?, tonRates: Rates.Rate?) {
        switch itemTransferModel.transferItem {
        case .ton:
            let tonRates = rates.ton.first(where: { $0.currency == .USD })
            return (tonRates, tonRates)
        case .token(_, let tokenInfo):
            let tokenRates = rates.tokens
                .first(where: { $0.tokenInfo == tokenInfo })?
                .rates
                .first(where: { $0.currency == .USD })
            let tonRates = rates.ton.first(where: { $0.currency == .USD })
            return (tokenRates, tonRates)
        }
    }
    
    func loadRates(itemTransferModel: ItemTransferModel) async throws -> Rates {
        do {
            switch itemTransferModel.transferItem {
            case .ton:
                return try await rateService.loadRates(tonInfo: TonInfo(), tokens: [], currencies: [.USD])
            case .token(_, let tokenInfo):
                return try await rateService.loadRates(tonInfo: TonInfo(), tokens: [tokenInfo], currencies: [.USD])
            }
        } catch {
            return try rateService.getRates()
        }
    }
}
