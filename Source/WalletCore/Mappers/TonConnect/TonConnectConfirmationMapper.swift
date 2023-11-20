//
//  TonConnectConfirmationMapper.swift
//
//
//  Created by Grigory Serebryanyy on 31.10.2023.
//

import Foundation
import TonAPI
import BigInt
import WalletCoreCore

struct TonConnectConfirmationMapper {
    private let accountEventMapper: AccountEventMapper
    private let amountFormatter: AmountFormatter
    
    init(accountEventMapper: AccountEventMapper,
         amountFormatter: AmountFormatter) {
        self.accountEventMapper = accountEventMapper
        self.amountFormatter = amountFormatter
    }
    
    func mapTransactionInfo(_ info: Components.Schemas.MessageConsequences,
                            tonRates: Rates.Rate?,
                            currency: Currency,
                            collectibles: Collectibles) throws -> TonConnectConfirmationModel {
        let tonInfo = TonInfo()
        let descriptionProvider = TonConnectConfirmationAccountEventRightTopDescriptionProvider(
            rates: tonRates,
            currency: currency,
            formatter: amountFormatter
        )
        
        let eventModel = accountEventMapper
            .mapActivityEvent(
                try .init(accountEvent: info.event),
                collectibles: collectibles,
                accountEventRightTopDescriptionProvider: descriptionProvider
            )
        
        var feeFormatted = "\(String.Symbol.almostEqual)\(String.Symbol.shortSpace)"
        + amountFormatter.formatAmount(
            BigInt(integerLiteral: abs(info.event.extra)),
            fractionDigits: tonInfo.fractionDigits,
            maximumFractionDigits: tonInfo.fractionDigits,
            currency: .TON)
        
        if let tonRates = tonRates {
            let rateConverter = RateConverter()
            let feeConverted = rateConverter.convert(
                amount: abs(info.event.extra),
                amountFractionLength: tonInfo.fractionDigits,
                rate: tonRates
            )
            let formattedFeeConverted = amountFormatter.formatAmount(
                feeConverted.amount,
                fractionDigits: feeConverted.fractionLength,
                maximumFractionDigits: 2,
                currency: currency)
            feeFormatted += "\(String.Symbol.shortSpace)\(String.Symbol.middleDot)\(String.Symbol.shortSpace)"
            + formattedFeeConverted
        }
        
        return TonConnectConfirmationModel(
            event: eventModel,
            fee: feeFormatted
        )
    }
}
