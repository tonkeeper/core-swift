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
    
    public func getInitialTransactionModel() -> SendTransactionViewModel {
        let mapper = SendConfirmationMapper(bigIntAmountFormatter: bigIntAmountFormatter)
        
        let mapperRates: (tokenRates: Rates.Rate?, tonRates: Rates.Rate?)
        if let cachedRates = try? rateService.getRates() {
            mapperRates = getRates(tokenTransferModel: tokenTransferModel, rates: cachedRates)
        } else {
            mapperRates = (nil, nil)
        }

        let model = mapper.mapItemTransferModel(
            tokenTransferModel,
            recipientAddress: recipient.address.shortString,
            recipientName: recipient.domain,
            fee: nil,
            comment: comment,
            rate: mapperRates.tonRates,
            tonRate: mapperRates.tonRates)
        return SendTransactionViewModel.token(model)

    }
    
    public func loadTransactionModel() async throws -> SendTransactionViewModel {
        async let ratesTask = loadRates(tokenTransferModel: tokenTransferModel)
        async let transactionBocTask = prepareSendTransaction(tokenTransferModel: tokenTransferModel,
                                                              recipientAddress: recipient.address,
                                                              comment: comment)
        
        let mapperRates: (tokenRates: Rates.Rate?, tonRates: Rates.Rate?)
        if let loadedRates = try? await ratesTask {
            mapperRates = getRates(tokenTransferModel: tokenTransferModel, rates: loadedRates)
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
        return SendTransactionViewModel.token(transactionModel)

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
                tokenAddress: tokenAddress.toString(),
                value: tokenTransferModel.amount,
                recipientAddress: recipientAddress,
                comment: comment
            )
        }
    }
    
    func getAction(transactionInfo: TransferTransactionInfo) throws -> TransferTransactionInfo.Action {
        if let jettonTransferAction = transactionInfo.actions.first(where: { $0.type == .jettonTransfer }) {
            return jettonTransferAction
        }
        
        if let tonTransfer = transactionInfo.actions.last {
            return tonTransfer
        }
        
        throw SendControllerError.failedToEmulateTransaction
    }
    
    func getRates(tokenTransferModel: TokenTransferModel, rates: Rates) -> (tokenRates: Rates.Rate?, tonRates: Rates.Rate?) {
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
    
    func loadRates(tokenTransferModel: TokenTransferModel) async throws -> Rates {
        do {
            switch tokenTransferModel.transferItem {
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
