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
    
    enum Error: Swift.Error {
        case noValidActionInTransactionInfo
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
    
    public func prepareSendTonTransaction(value: BigInt,
                                          address: String,
                                          comment: String?) async throws -> String {
        return try await sendExternalMessage { sender in
            let recipient = try Address.parse(address)
            
            let internalMessage: MessageRelaxed
            if let comment = comment {
                internalMessage = try MessageRelaxed.internal(to: recipient,
                                                              value: value.magnitude,
                                                              textPayload: comment)
            } else {
                internalMessage = MessageRelaxed.internal(to: recipient,
                                                          value: value.magnitude)
            }
            return internalMessage
        }
    }
    
    public func prepareSendTokenTransaction(tokenAddress: String, value: BigInt, address: String, comment: String?) async throws -> String {
        return try await sendExternalMessage { sender in
            let recipient = try Address.parse(address)
            
            let internalMessage = try JettonTransferMessage.internalMessage(jettonAddress: try Address.parse(tokenAddress),
                                                                            amount: value,
                                                                            to: recipient,
                                                                            from: sender,
                                                                            comment: comment)
            return internalMessage
        }
    }
    
    public func loadTransactionInformation(transactionBoc: String) async throws -> SendTransactionModel {
        let transactionInfo = try await sendService.loadTransactionInfo(boc: transactionBoc)
        let action = try getAction(transactionInfo: transactionInfo)
        let rates = await getRates(action: action)
        let mapper = SendActionMapper(bigIntAmountFormatter: bigIntAmountFormatter)
        let tokenModel = mapper.mapAction(action: action,
                                          fee: transactionInfo.fee,
                                          comment: action.comment,
                                          rate: rates.tokenRates,
                                          tonRate: rates.tonRates)
        return .init(tokenModel: tokenModel, boc: transactionBoc)
    }
    
    public func sendTransaction(boc: String) async throws {
        try await sendService.sendTransaction(boc: boc)
    }
}

private extension SendController {
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
        
        throw Error.noValidActionInTransactionInfo
    }
    
    func getRates(action: TransferTransactionInfo.Action) async -> (tokenRates: Rates.Rate?, tonRates: Rates.Rate?) {
        do {
            switch action.transfer {
            case .ton:
                let rates = try await rateService.loadRates(tonInfo: TonInfo(), tokens: [], currencies: [.USD])
                let tonRates = rates.ton.first(where: { $0.currency == .USD })
                return (tonRates, tonRates)
            case .token(let tokenInfo):
                let rates = try await rateService.loadRates(tonInfo: TonInfo(), tokens: [tokenInfo], currencies: [.USD])
                let tokenRates = rates.tokens
                    .first(where: { $0.tokenInfo == tokenInfo })?
                    .rates
                    .first(where: { $0.currency == .USD })
                let tonRates = rates.ton.first(where: { $0.currency == .USD })
                return (tokenRates, tonRates)
                
            }
        } catch {
            return (nil, nil)
        }
    }
}
