//
//  TokenSendController.swift
//
//
//  Created by Grigory on 30.8.23..
//

import Foundation
import TonSwift
import BigInt

public final class TokenSendController: SendController {
    
    weak public var delegate: SendControllerDelegate?
    
    private let tokenTransferModel: TokenTransferModel
    private let recipient: Recipient
    private let comment: String?
    private let sendService: SendService
    private let rateService: RatesService
    private let sendMessageBuilder: SendMessageBuilder
    private let intAmountFormatter: IntAmountFormatter
    private let bigIntAmountFormatter: BigIntAmountFormatter
    
    init(tokenTransferModel: TokenTransferModel,
         recipient: Recipient,
         comment: String?,
         sendService: SendService,
         rateService: RatesService,
         sendMessageBuilder: SendMessageBuilder,
         intAmountFormatter: IntAmountFormatter,
         bigIntAmountFormatter: BigIntAmountFormatter) {
        self.tokenTransferModel = tokenTransferModel
        self.recipient = recipient
        self.comment = comment
        self.sendService = sendService
        self.rateService = rateService
        self.sendMessageBuilder = sendMessageBuilder
        self.intAmountFormatter = intAmountFormatter
        self.bigIntAmountFormatter = bigIntAmountFormatter
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
        let transactionBoc = try await prepareSendTransaction(
            tokenTransferModel: tokenTransferModel,
            recipientAddress: recipient.address,
            comment: comment
        )
        
        try await sendService.sendTransaction(boc: transactionBoc)
    }
}

private extension TokenSendController {
    func buildInitialModel() -> SendTransactionViewModel {
        let mapper = SendConfirmationMapper(bigIntAmountFormatter: bigIntAmountFormatter)
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
        let mapper = SendConfirmationMapper(bigIntAmountFormatter: bigIntAmountFormatter)
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
        let mapper = SendConfirmationMapper(bigIntAmountFormatter: bigIntAmountFormatter)
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
            comment: comment)
        
        let rates = await ratesTask
        let transactionBoc = try await transactionBocTask
        let transactionInfo = try await sendService.loadTransactionInfo(boc: transactionBoc)
        
        return buildEmulationModel(
            fee: transactionInfo.fee,
            tonRates: rates.tonRates,
            tokenRates: rates.tokenRates)
    }
    
    func prepareSendTransaction(tokenTransferModel: TokenTransferModel,
                                recipientAddress: Address,
                                comment: String?) async throws -> String {
        switch tokenTransferModel.transferItem {
        case .ton:
            return try await sendMessageBuilder.sendTonTransactionBoc(
                value: tokenTransferModel.amount,
                recipientAddress: recipientAddress,
                comment: comment
            )
        case .token(let tokenAddress, _):
            return try await sendMessageBuilder.sendTokenTransactionBoc(
                tokenAddress: tokenAddress.toRaw(),
                value: tokenTransferModel.amount,
                recipientAddress: recipientAddress,
                comment: comment
            )
        }
    }
    
    func loadRates(for tokenTransferModel: TokenTransferModel) async -> (tokenRates: Rates.Rate?, tonRates: Rates.Rate?) {
        let tokens: [TokenInfo]
        switch tokenTransferModel.transferItem {
        case .ton:
            tokens = []
        case .token(_, let tokenInfo):
            tokens = [tokenInfo]
        }
        if let rates = try? await rateService.loadRates(tonInfo: TonInfo(), tokens: tokens, currencies: [.USD]) {
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
}
