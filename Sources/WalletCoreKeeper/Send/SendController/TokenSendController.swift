//
//  TokenSendController.swift
//
//
//  Created by Grigory on 30.8.23..
//

import Foundation
import TonSwift
import BigInt
import WalletCoreCore

public final class TokenSendController: SendController {
    
    weak public var delegate: SendControllerDelegate?
    
    private let tokenTransferModel: TokenTransferModel
    private let recipient: Recipient
    private let comment: String?
    private let walletProvider: WalletProvider
    private let sendService: SendService
    private let rateService: RatesService
    private let intAmountFormatter: IntAmountFormatter
    private let amountFormatter: AmountFormatter
    
    private var currency: Currency {
        (try? walletProvider.activeWallet.currency) ?? .USD
    }
    
    init(tokenTransferModel: TokenTransferModel,
         recipient: Recipient,
         comment: String?,
         walletProvider: WalletProvider,
         sendService: SendService,
         rateService: RatesService,
         intAmountFormatter: IntAmountFormatter,
         amountFormatter: AmountFormatter) {
        self.tokenTransferModel = tokenTransferModel
        self.recipient = recipient
        self.comment = comment
        self.walletProvider = walletProvider
        self.sendService = sendService
        self.rateService = rateService
        self.intAmountFormatter = intAmountFormatter
        self.amountFormatter = amountFormatter
    }
    
    // MARK: - SendController
    
    public func prepareTransaction() {
        let model = buildInitialModel()
        delegate?.sendController(self, didUpdate: model)
        
        Task {
            do {
                let emulateModel = try await emulateTransaction()
                await MainActor.run {
                    delegate?.sendController(self, didUpdate: emulateModel)
                }
            } catch {
                await MainActor.run {
                    let model = buildEmulationFailedModel()
                    delegate?.sendController(self, didUpdate: model)
                    delegate?.sendControllerFailed(self, error: .failedToEmulateTransaction)
                }
            }
        }
    }
    
    public func sendTransaction() async throws {
        let wallet = try walletProvider.activeWallet
        let transactionBoc = try await prepareSendTransaction(
            tokenTransferModel: tokenTransferModel,
            recipientAddress: recipient.address,
            comment: comment) { transfer in
                if wallet.isRegular {
                    let privateKey = try walletProvider.getWalletPrivateKey(wallet)
                    return try transfer.signMessage(signer: WalletTransferSecretKeySigner(secretKey: privateKey.data))
                }
                // TBD: External wallet sign
                return try transfer.signMessage(signer: WalletTransferEmptyKeySigner())
            }
        
        try await sendService.sendTransaction(boc: transactionBoc)
    }
}

private extension TokenSendController {
    func buildInitialModel() -> SendTransactionViewModel {
        let mapper = SendConfirmationMapper(amountFormatter: amountFormatter)
        let rates = getCachedRates(for: tokenTransferModel)
        let model = mapper.mapTokenTransfer(
            tokenTransferModel,
            recipientAddress: recipient.address.toShortString(bounceable: false),
            recipientName: recipient.domain,
            fee: nil,
            comment: comment,
            rate: rates.tokenRates,
            tonRate: rates.tonRates,
            isInitial: true)
        return .token(model)
    }
    
    func buildEmulationModel(fee: Int64?,
                             tonRates: Rates.Rate?,
                             tokenRates: Rates.Rate?) -> SendTransactionViewModel {
        let mapper = SendConfirmationMapper(amountFormatter: amountFormatter)
        let model = mapper.mapTokenTransfer(
            tokenTransferModel,
            recipientAddress: recipient.address.toShortString(bounceable: false),
            recipientName: recipient.domain,
            fee: fee,
            comment: comment,
            rate: tokenRates,
            tonRate: tonRates,
            isInitial: false)
        return .token(model)
    }
    
    func buildEmulationFailedModel() -> SendTransactionViewModel {
        let mapper = SendConfirmationMapper(amountFormatter: amountFormatter)
        let rates = getCachedRates(for: tokenTransferModel)
        let model = mapper.mapTokenTransfer(
            tokenTransferModel,
            recipientAddress: recipient.address.toShortString(bounceable: false),
            recipientName: recipient.domain,
            fee: nil,
            comment: comment,
            rate: rates.tokenRates,
            tonRate: rates.tonRates,
            isInitial: true)
        return .token(model)
    }
    
    func emulateTransaction() async throws -> SendTransactionViewModel {
        async let ratesTask = loadRates(for: tokenTransferModel)
        async let transactionBocTask = prepareSendTransaction(
            tokenTransferModel: tokenTransferModel,
            recipientAddress: recipient.address,
            comment: comment,
            signClosure: { try $0.signMessage(signer: WalletTransferEmptyKeySigner()) })
        
        let rates = await ratesTask
        let transactionBoc = try await transactionBocTask
        let transactionInfo = try await sendService.loadTransactionInfo(boc: transactionBoc)
        
        let transferTransactionInfo = TransferTransactionInfo(
            accountEvent: transactionInfo.event,
            risk: transactionInfo.risk,
            transaction: transactionInfo.trace.transaction)

        return buildEmulationModel(
            fee: transferTransactionInfo.fee,
            tonRates: rates.tonRates,
            tokenRates: rates.tokenRates)
    }
    
    func prepareSendTransaction(tokenTransferModel: TokenTransferModel,
                                recipientAddress: Address,
                                comment: String?,
                                signClosure: (WalletTransfer) async throws -> Cell) async throws -> String {
        let wallet = try walletProvider.activeWallet
        let seqno = try await sendService.loadSeqno(address: wallet.address)
        let boc: String
        switch tokenTransferModel.transferItem {
        case .ton:
            boc = try await WalletCoreCore.TonTransferMessageBuilder.sendTonTransfer(
                wallet: try walletProvider.activeWallet,
                seqno: seqno,
                value: tokenTransferModel.amount,
                recipientAddress: recipientAddress,
                comment: comment,
                signClosure: signClosure)
        case .token(let tokenAddress, _):
            boc = try await WalletCoreCore.TokenTransferMessageBuilder.sendTokenTransfer(
                wallet: wallet,
                seqno: seqno,
                tokenAddress: tokenAddress,
                value: tokenTransferModel.amount,
                recipientAddress: recipientAddress,
                comment: comment,
                signClosure: signClosure)
        }
        return boc
    }
    
    func loadRates(for tokenTransferModel: TokenTransferModel) async -> (tokenRates: Rates.Rate?, tonRates: Rates.Rate?) {
        let tokens: [TokenInfo]
        switch tokenTransferModel.transferItem {
        case .ton:
            tokens = []
        case .token(_, let tokenInfo):
            tokens = [tokenInfo]
        }
        if let rates = try? await rateService.loadRates(tonInfo: TonInfo(), tokens: tokens, currencies: [currency]) {
            return getRates(for: tokenTransferModel, rates: rates)
        } else {
            return getCachedRates(for: tokenTransferModel)
        }
    }
    
    func getCachedRates(for tokenTransferModel: TokenTransferModel) -> (tokenRates: Rates.Rate?, tonRates: Rates.Rate?) {
        guard let rates = try? rateService.getRates() else { return (nil, nil) }
        return getRates(for: tokenTransferModel, rates: rates)
    }
    
    func getRates(for tokenTransferModel: TokenTransferModel, rates: Rates) -> (tokenRates: Rates.Rate?, tonRates: Rates.Rate?) {
        switch tokenTransferModel.transferItem {
        case .ton:
            let tonRates = rates.ton.first(where: { $0.currency == currency })
            return (tonRates, tonRates)
        case .token(_, let tokenInfo):
            let tokenRates = rates.tokens
                .first(where: { $0.tokenInfo == tokenInfo })?
                .rates
                .first(where: { $0.currency == currency })
            let tonRates = rates.ton.first(where: { $0.currency == currency })
            return (tokenRates, tonRates)
        }
    }
}
