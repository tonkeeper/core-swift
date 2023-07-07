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
    
    public func prepareTransaction(value: BigInt,
                                   address: String,
                                   comment: String?) async throws -> String {
        let wallet = try walletProvider.activeWallet
        let walletPublicKey = try wallet.publicKey
        let mnemonicVault = try KeychainMnemonicVault(keychainManager: keychainManager, walletID: wallet.identity.id())
        let contractBuilder = WalletContractBuilder()
        let contract = try contractBuilder.walletContract(with: walletPublicKey,
                                                          contractVersion: wallet.contractVersion)
        let mnemonic = try mnemonicVault.loadValue(key: walletPublicKey)
        let keyPair = try Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonic)
        
        let senderAddress = try contract.address()
        let destinationAddress = try Address.parse(address)
        
        let internalMessage: MessageRelaxed
        if let comment = comment {
            internalMessage = try MessageRelaxed.internal(to: destinationAddress,
                                                          value: value.magnitude,
                                                          textPayload: comment)
        } else {
            internalMessage = MessageRelaxed.internal(to: destinationAddress,
                                                          value: value.magnitude)
        }
        
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
    
    public func loadTransactionInformation(transactionBoc: String) async throws -> SendTransactionModel {
        let transactionInfo = try await sendService.loadTransactionInfo(boc: transactionBoc)
        guard let action = transactionInfo.actions.first else { throw NSError(domain: "", code: 1) }

        let tonInfo = TonInfo()
        let amountToken = bigIntAmountFormatter.format(amount: action.amount,
                                                       fractionDigits: tonInfo.fractionDigits,
                                                       maximumFractionDigits: tonInfo.fractionDigits,
                                                       symbol: nil)
        
        let feeTon = bigIntAmountFormatter.format(amount: BigInt(transactionInfo.fee),
                                                  fractionDigits: tonInfo.fractionDigits,
                                                  maximumFractionDigits: tonInfo.fractionDigits,
                                                  symbol: nil)
        
        var amountFiatString: String?
        var feeFiatString: String?
        let rates = try await rateService.loadRates(tonInfo: tonInfo, tokens: [], currencies: [.USD])
        let rateConverter = RateConverter()
        if let tonRate = rates.ton.first(where: { $0.currency == .USD }) {
            let fiat = rateConverter.convert(amount: action.amount, amountFractionLength: tonInfo.fractionDigits, rate: tonRate)
            let fiatFormatted = bigIntAmountFormatter.format(amount: fiat.amount,
                                                             fractionDigits: fiat.fractionLength,
                                                             maximumFractionDigits: 2,
                                                             symbol: tonRate.currency.symbol)
            
            let feeFiat = rateConverter.convert(amount: BigInt(transactionInfo.fee), amountFractionLength: tonInfo.fractionDigits, rate: tonRate)
            let feeFiatFormatted = bigIntAmountFormatter.format(amount: feeFiat.amount,
                                                                fractionDigits: feeFiat.fractionLength,
                                                                maximumFractionDigits: 2,
                                                                symbol: tonRate.currency.symbol)
            amountFiatString = "≈\(fiatFormatted)"
            feeFiatString = "≈\(feeFiatFormatted)"
        }
        
        
        return SendTransactionModel(title: action.name,
                                    address: action.recipient.shortString,
                                    amountToken: "\(amountToken) \(tonInfo.symbol)",
                                    amountFiat: amountFiatString,
                                    feeTon: "≈\(feeTon) \(tonInfo.symbol)",
                                    feeFiat: feeFiatString,
                                    boc: transactionBoc)
    }
    
    public func sendTransaction(boc: String) async throws {
        try await sendService.sendTransaction(boc: boc)
    }
}
