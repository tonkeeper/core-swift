//
//  NFTSendController.swift
//
//
//  Created by Grigory on 30.8.23..
//

import Foundation
import TonSwift
import BigInt
import WalletCoreCore

public final class NFTSendController: SendController {
    
    weak public var delegate: SendControllerDelegate?
    
    // MARK: - Dependencies
    
    private let nftAddress: Address
    private let recipient: Recipient
    private let comment: String?
    private let walletProvider: WalletProvider
    private let sendService: SendService
    private let rateService: RatesService
    private let collectibleService: CollectiblesService
    private let amountFormatter: AmountFormatter
    private let bigIntAmountFormatter: BigIntAmountFormatter
    
    private var currency: Currency {
        (try? walletProvider.activeWallet.currency) ?? .USD
    }
    
    // MARK: - State
    
    private var transactionEmulationExtra: Int64 = 0
    private var nft: Collectible?

    init(nftAddress: Address,
         recipient: Recipient,
         comment: String?,
         walletProvider: WalletProvider,
         sendService: SendService,
         rateService: RatesService,
         collectibleService: CollectiblesService,
         amountFormatter: AmountFormatter,
         bigIntAmountFormatter: BigIntAmountFormatter) {
        self.nftAddress = nftAddress
        self.recipient = recipient
        self.comment = comment
        self.walletProvider = walletProvider
        self.sendService = sendService
        self.rateService = rateService
        self.collectibleService = collectibleService
        self.amountFormatter = amountFormatter
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
                recipientAddress: recipient.address.address,
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
        let mapper = SendConfirmationMapper(amountFormatter: amountFormatter)
        
        let model = mapper.mapNFT(
            nft,
            recipientAddress: recipient.shortAddress,
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
        let mapper = SendConfirmationMapper(amountFormatter: amountFormatter)
        
        let model = mapper.mapNFT(
            nft,
            recipientAddress: recipient.shortAddress,
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
            recipientAddress: recipient.address.address,
            comment: comment)
        
        let transactionBoc = try await transactionBocTask
        let transactionInfo = try await sendService.loadTransactionInfo(boc: transactionBoc)
        let rates = try await ratesTask
        
        let transferTransactionInfo = TransferTransactionInfo(
            accountEvent: transactionInfo.event,
            risk: transactionInfo.risk,
            transaction: transactionInfo.trace.transaction)
        transactionEmulationExtra = transferTransactionInfo.extra
        
        return buildEmulationModel(
            nft: nft,
            fee: transferTransactionInfo.fee,
            tonRate: rates
        )
    }
    
    func prepareEmulateTransaction(nft: Collectible,
                                   recipientAddress: Address,
                                   comment: String?) async throws -> String {
        let transferAmount = BigUInt(stringLiteral: "10000000000")
        let wallet = try walletProvider.activeWallet
        let seqno = try await sendService.loadSeqno(address: wallet.address)
        return try await NFTTransferMessageBuilder.sendNFTTransfer(
            wallet: wallet,
            seqno: seqno,
            nftAddress: nft.address,
            recipientAddress: recipientAddress,
            transferAmount: transferAmount) { transfer in
                try transfer.signMessage(signer: WalletTransferEmptyKeySigner())
            }
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
        let wallet = try walletProvider.activeWallet
        let seqno = try await sendService.loadSeqno(address: wallet.address)
        return try await NFTTransferMessageBuilder.sendNFTTransfer(
            wallet: wallet,
            seqno: seqno,
            nftAddress: nft.address,
            recipientAddress: recipientAddress,
            transferAmount: transferAmount.magnitude) { transfer in
                if wallet.isRegular {
                    let privateKey = try walletProvider.getWalletPrivateKey(wallet)
                    return try transfer.signMessage(signer: WalletTransferSecretKeySigner(secretKey: privateKey.data))
                }
                // TBD: External wallet sign
                return try transfer.signMessage(signer: WalletTransferEmptyKeySigner())
            }
    }

    func getTonRates() async throws -> Rates.Rate? {
        do {
            let loadedRates = try await rateService.loadRates(
                tonInfo: TonInfo(),
                tokens: [],
                currencies: [currency])
            return loadedRates.ton.first(where: { $0.currency == currency })
        } catch {
            return try? rateService.getRates().ton.first(where: { $0.currency == currency })
        }
    }
}
