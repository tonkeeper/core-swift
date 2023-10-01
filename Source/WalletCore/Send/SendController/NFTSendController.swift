//
//  NFTSendController.swift
//
//
//  Created by Grigory on 30.8.23..
//

import Foundation
import TonSwift
import BigInt

public final class NFTSendController: SendController {
    
    weak public var delegate: SendControllerDelegate?
    
    // MARK: - Dependencies
    
    private let nftAddress: Address
    private let recipient: Recipient
    private let comment: String?
    private let sendService: SendService
    private let rateService: RatesService
    private let collectibleService: CollectiblesService
    private let sendMessageBuilder: SendMessageBuilder
    private let intAmountFormatter: IntAmountFormatter
    private let bigIntAmountFormatter: BigIntAmountFormatter
    
    // MARK: - State
    
    private var transactionEmulationExtra: Int64 = 0
    private var nft: Collectible?

    init(nftAddress: Address,
         recipient: Recipient,
         comment: String?,
         sendService: SendService,
         rateService: RatesService,
         collectibleService: CollectiblesService,
         sendMessageBuilder: SendMessageBuilder,
         intAmountFormatter: IntAmountFormatter,
         bigIntAmountFormatter: BigIntAmountFormatter) {
        self.nftAddress = nftAddress
        self.recipient = recipient
        self.comment = comment
        self.sendService = sendService
        self.rateService = rateService
        self.collectibleService = collectibleService
        self.sendMessageBuilder = sendMessageBuilder
        self.intAmountFormatter = intAmountFormatter
        self.bigIntAmountFormatter = bigIntAmountFormatter
    }
    
    public func prepareTransaction() {
        Task { [collectibleService] in
            var nft: Collectible?
            
            if let cachedNFT = try? collectibleService.getCollectible(address: nftAddress) {
                nft = cachedNFT
            } else {
                await MainActor.run {
                    delegate?.sendControllerDidStartLoadInitialData(self)
                }
                nft = try? await collectibleService.loadCollectibles(addresses: [nftAddress]).collectibles[nftAddress]
            }
            
            guard let nft = nft else {
                await MainActor.run {
                    delegate?.sendControllerFailed(self, error: .failedToPrepareTransaction)
                }
                return
            }
            
            self.nft = nft
            
            let model = buildInitialModel(nft: nft)
            await MainActor.run {
                delegate?.sendController(self, didUpdate: model)
            }
            
            do {
                let emulateModel = try await emulateTransaction(nft: nft)
                await MainActor.run {
                    delegate?.sendController(self, didUpdate: emulateModel)
                }
            } catch {
                await MainActor.run {
                    let model = buildEmulationModel(
                        nft: nft,
                        fee: nil,
                        tonRate: nil)
                    delegate?.sendController(self, didUpdate: model)
                    delegate?.sendControllerFailed(self, error: .failedToEmulateTransaction)
                }
            }
        }
    }
    
    public func sendTransaction() async throws {
        guard let nft = nft else {
            throw SendControllerError.failedToSendTransaction
        }
        do {
            let transactionBoc = try await prepareSendTransaction(
                nft: nft,
                recipientAddress: recipient.address,
                comment: comment)
            try await sendService.sendTransaction(boc: transactionBoc)
        } catch {
            delegate?.sendControllerFailed(self, error: .failedToSendTransaction)
            throw SendControllerError.failedToSendTransaction
        }
    }
}

private extension NFTSendController {
    func buildInitialModel(nft: Collectible) -> SendTransactionViewModel {
        let mapper = SendConfirmationMapper(bigIntAmountFormatter: bigIntAmountFormatter)
        
        let model = mapper.mapNFT(
            nft,
            recipientAddress: recipient.address.toShortString(bounceable: false),
            recipientName: recipient.domain,
            fee: nil,
            comment: comment,
            tonRate: nil,
            isInitial: true
        )
        
        return .nft(model)
    }
    
    func buildEmulationModel(nft: Collectible,
                             fee: Int64?,
                             tonRate: Rates.Rate?) -> SendTransactionViewModel {
        let mapper = SendConfirmationMapper(bigIntAmountFormatter: bigIntAmountFormatter)
        
        let model = mapper.mapNFT(
            nft,
            recipientAddress: recipient.address.toShortString(bounceable: false),
            recipientName: recipient.domain,
            fee: fee,
            comment: comment,
            tonRate: tonRate,
            isInitial: false
        )
        
        return .nft(model)
    }
    
    func emulateTransaction(nft: Collectible) async throws -> SendTransactionViewModel {
        async let ratesTask = getTonRates()
        async let transactionBocTask = prepareEmulateTransaction(
            nft: nft,
            recipientAddress: recipient.address,
            comment: comment)
        
        let transactionBoc = try await transactionBocTask
        let transactionInfo = try await sendService.loadTransactionInfo(boc: transactionBoc)
        let rates = try await ratesTask
        transactionEmulationExtra = transactionInfo.extra
        
        return buildEmulationModel(
            nft: nft,
            fee: transactionInfo.fee,
            tonRate: rates
        )
    }
    
    func prepareEmulateTransaction(nft: Collectible,
                                   recipientAddress: Address,
                                   comment: String?) async throws -> String {
        let transferAmount = BigUInt(stringLiteral: "10000000000")
        return try await sendMessageBuilder.sendNFTEstimateBoc(
            nftAddress: nft.address,
            recipientAddress: recipientAddress,
            transferAmount: transferAmount
        )
    }
    
    func prepareSendTransaction(nft: Collectible,
                                recipientAddress: Address,
                                comment: String?) async throws -> String {
        let emulationExtra = BigInt(integerLiteral: transactionEmulationExtra)
        let minimumTransferAmount = BigInt(stringLiteral: "50000000")
        var transferAmount = emulationExtra + minimumTransferAmount
        transferAmount = transferAmount < minimumTransferAmount
        ? minimumTransferAmount
        : transferAmount
        return try await sendMessageBuilder.sendNFTEstimateBoc(
            nftAddress: nft.address,
            recipientAddress: recipientAddress,
            transferAmount: transferAmount.magnitude
        )
    }

    func getTonRates() async throws -> Rates.Rate? {
        do {
            let loadedRates = try await rateService.loadRates(
                tonInfo: TonInfo(),
                tokens: [],
                currencies: [.USD])
            return loadedRates.ton.first(where: { $0.currency == .USD })
        } catch {
            return try? rateService.getRates().ton.first(where: { $0.currency == .USD })
        }
    }
}
