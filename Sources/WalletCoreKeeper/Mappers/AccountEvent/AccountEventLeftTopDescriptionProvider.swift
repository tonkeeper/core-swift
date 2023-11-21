//
//  AccountEventLeftTopDescriptionProvider.swift
//  
//
//  Created by Grigory Serebryanyy on 30.10.2023.
//

import Foundation
import BigInt
import WalletCoreCore

protocol AccountEventRightTopDescriptionProvider {
    mutating func rightTopDescription(accountEvent: AccountEvent,
                                     action: Action) -> String?
}

struct ActivityAccountEventRightTopDescriptionProvider: AccountEventRightTopDescriptionProvider {
    private let dateFormatter: DateFormatter
    private let dateFormat: String
    
    init(dateFormatter: DateFormatter,
         dateFormat: String) {
        self.dateFormatter = dateFormatter
        self.dateFormat = dateFormat
    }
    
    mutating func rightTopDescription(accountEvent: AccountEvent,
                                      action: Action) -> String? {
        dateFormatter.dateFormat = dateFormat
        let eventDate = Date(timeIntervalSince1970: accountEvent.timestamp)
        return dateFormatter.string(from: eventDate)
    }
}

struct TonConnectConfirmationAccountEventRightTopDescriptionProvider: AccountEventRightTopDescriptionProvider {
    private let rates: Rates.Rate?
    private let currency: Currency
    private let formatter: AmountFormatter
    
    init(rates: Rates.Rate?,
         currency: Currency,
         formatter: AmountFormatter) {
        self.rates = rates
        self.currency = currency
        self.formatter = formatter
    }
    
    mutating func rightTopDescription(accountEvent: AccountEvent,
                                      action: Action) -> String? {
        guard let rates = rates else { return nil }
        
        let rateConverter = RateConverter()
        let convertResult: (BigInt, Int)
        let tonInfo = TonInfo()
        
        switch action.type {
        case .tonTransfer(let tonTransfer):
            convertResult = rateConverter.convert(
                amount: tonTransfer.amount,
                amountFractionLength: TonInfo().fractionDigits,
                rate: rates)
        case .nftPurchase(let nftPurchase):
            convertResult = rateConverter.convert(
                amount: nftPurchase.price,
                amountFractionLength: tonInfo.fractionDigits,
                rate: rates)
        default:
            return nil
        }
        return "\(currency.symbol)" + formatter.formatAmount(
            convertResult.0,
            fractionDigits: convertResult.1,
            maximumFractionDigits: 2)
    }
}
