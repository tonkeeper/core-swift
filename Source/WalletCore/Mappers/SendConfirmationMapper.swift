//
//  SendConfirmationMapper.swift
//
//
//  Created by Grigory on 12.7.23..
//

import Foundation
import BigInt

struct SendConfirmationMapper {
    private let amountFormatter: AmountFormatter
    
    init(amountFormatter: AmountFormatter) {
        self.amountFormatter = amountFormatter
    }
    
    func mapTokenTransfer(_ tokenTransferModel: TokenTransferModel,
                          recipientAddress: String?,
                          recipientName: String?,
                          fee: Int64?,
                          comment: String?,
                          rate: Rates.Rate?,
                          tonRate: Rates.Rate?,
                          isInitial: Bool) -> SendTransactionViewModel.SendTokenModel {
        let token: FormatterTokenInfo
        let image: Image
        let name: String
        switch tokenTransferModel.transferItem {
        case .token(_, let tokenInfo):
            name = "\(tokenInfo.symbol ?? "Token") Transfer"
            token = tokenInfo
            image = .url(tokenInfo.imageURL)
        case .ton:
            name = "Ton Transfer"
            token = TonInfo()
            image = .ton
        }
        
        let amountFormatted = amountFormatter.formatAmount(
            tokenTransferModel.amount,
            fractionDigits: token.fractionDigits,
            maximumFractionDigits: token.fractionDigits
        )
        
        let feeTon: ViewModelLoadableItem<String?>
        let feeFiat: ViewModelLoadableItem<String?>
        
        if isInitial {
            feeTon = .loading
            feeFiat = .loading
        } else {
            let mappedFee = mapFee(fee, tonRate: tonRate)
            feeTon = .value(mappedFee.mappedFee)
            feeFiat = .value(mappedFee.mappedFiatFee)
        }
        
        let fiatAmount: ViewModelLoadableItem<String?>
        if let mappedFiatAmount = mapFiatAmount(
            amount: tokenTransferModel.amount,
            formatterInfo: token,
            rate: rate) {
            fiatAmount = .value(mappedFiatAmount)
        } else if isInitial {
            fiatAmount = .loading
        } else {
            fiatAmount = .value(nil)
        }
        
        return SendTransactionViewModel.SendTokenModel(
            title: name,
            image: image,
            recipientAddress: recipientAddress,
            recipientName: recipientName,
            amountToken: "\(amountFormatted) \(token.tokenSymbol ?? "")",
            amountFiat: fiatAmount,
            feeTon: feeTon,
            feeFiat: feeFiat,
            comment: comment)
    }
    
    func mapNFT(_ nft: Collectible,
                recipientAddress: String?,
                recipientName: String?,
                fee: Int64?,
                comment: String?,
                tonRate: Rates.Rate?,
                isInitial: Bool) -> SendTransactionViewModel.SendNFTModel {
        
        var description = ""
        if let name = nft.name {
            description = name
        }
        if let collectionName = nft.collection?.name {
            if !description.isEmpty {
                description.append(" · ")
            }
            description.append(collectionName)
        }
        
        let feeTon: ViewModelLoadableItem<String?>
        let feeFiat: ViewModelLoadableItem<String?>
        
        if isInitial {
            feeTon = .loading
            feeFiat = .loading
        } else {
            let mappedFee = mapFee(fee, tonRate: tonRate)
            feeTon = .value(mappedFee.mappedFee)
            feeFiat = .value(mappedFee.mappedFiatFee)
        }
        
        return SendTransactionViewModel.SendNFTModel(
            title: "NFT Transfer",
            description: description,
            image: .url(nft.preview.size500),
            recipientAddress: recipientAddress,
            recipientName: recipientName,
            feeTon: feeTon,
            feeFiat: feeFiat,
            comment: comment,
            nftId: nft.address.toShortString(bounceable: false),
            nftCollectionId: nft.collection?.address.toShortString(bounceable: false))
    }
}

private extension SendConfirmationMapper {
    func mapFee(_ fee: Int64?, tonRate: Rates.Rate?) -> (mappedFee: String?, mappedFiatFee: String?) {
        guard let fee = fee else { return ("?", nil) }
        let tonInfo = TonInfo()
        var mappedFee = amountFormatter.formatAmount(
            BigInt(fee),
            fractionDigits: tonInfo.fractionDigits,
            maximumFractionDigits: tonInfo.fractionDigits
        )
        mappedFee = "≈\(mappedFee) \(tonInfo.symbol)"
        
        var mappedFiatFee: String?
        if let tonRate = tonRate {
            let rateConverter = RateConverter()
            let feeFiat = rateConverter.convert(amount: fee, amountFractionLength: tonInfo.fractionDigits, rate: tonRate)
            let feeFiatFormatted = amountFormatter.formatAmount(
                feeFiat.amount,
                fractionDigits: feeFiat.fractionLength,
                maximumFractionDigits: 2,
                currency: tonRate.currency
            )
            mappedFiatFee = "≈\(feeFiatFormatted)"
        }
        return (mappedFee, mappedFiatFee)
    }
    
    func mapFiatAmount(amount: BigInt,
                       formatterInfo: FormatterTokenInfo,
                       rate: Rates.Rate?) -> String? {
        guard let rate = rate else { return nil }
        let rateConverter = RateConverter()
        let fiatConverted = rateConverter.convert(
            amount: amount,
            amountFractionLength: formatterInfo.fractionDigits,
            rate: rate
        )
        let fiatAmountFormatted = amountFormatter.formatAmount(
            fiatConverted.amount,
            fractionDigits: fiatConverted.fractionLength,
            maximumFractionDigits: 2,
            currency: rate.currency
        )
        
        return fiatAmountFormatted
    }
}
