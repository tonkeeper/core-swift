//
//  BalanceWidgetController.swift
//
//
//  Created by Grigory on 30.9.23..
//

import Foundation
import BigInt
import WalletCoreCore

public final class BalanceWidgetController {
    public enum Error: Swift.Error {
        case failedToLoad
        case noWallet
    }
    
    public struct Model {
        public let tonBalance: String
        public let fiatBalance: String
        public let address: String
        
        public init(tonBalance: String, fiatBalance: String, address: String) {
            self.tonBalance = tonBalance
            self.fiatBalance = fiatBalance
            self.address = address
        }
    }
    
    private let walletProvider: WalletProvider
    private let balanceService: WalletBalanceService
    private let ratesService: RatesService
    private let amountFormatter: AmountFormatter
    
    init(walletProvider: WalletProvider,
         balanceService: WalletBalanceService,
         ratesService: RatesService,
         amountFormatter: AmountFormatter) {
        self.walletProvider = walletProvider
        self.balanceService = balanceService
        self.ratesService = ratesService
        self.amountFormatter = amountFormatter
    }
    
    public func loadBalance(currency: Currency) async throws -> Model {
        guard let wallet = try? walletProvider.activeWallet else {
            throw Error.noWallet
        }
        
        do {
            let contract = try WalletContractBuilder().walletContract(with: try wallet.publicKey, contractVersion: wallet.contractVersion)
            async let balanceTask = balanceService.loadWalletBalance(wallet: wallet)
            async let ratesTask = ratesService.loadRates(tonInfo: TonInfo(),
                                                         tokens: [],
                                                         currencies: [currency])
            
            let balance = try await balanceTask
            let formattedFiatBalance: String
            if let rates = try? await ratesTask,
               let tonRate = rates.ton.first(where: { $0.currency == currency }) {
                let fiatAmount = RateConverter().convert(
                    amount: balance.tonBalance.amount.quantity,
                    amountFractionLength: balance.tonBalance.amount.tonInfo.fractionDigits,
                    rate: tonRate
                )
                formattedFiatBalance = amountFormatter.formatAmountWithoutFractionIfThousand(
                    fiatAmount.amount,
                    fractionDigits: fiatAmount.fractionLength,
                    maximumFractionDigits: 2,
                    currency: currency
                )
            } else {
                formattedFiatBalance = "\(currency.symbol)-----"
            }
            let formattedBalance = amountFormatter.formatAmount(
                BigInt(integerLiteral: balance.tonBalance.amount.quantity),
                fractionDigits: balance.tonBalance.amount.tonInfo.fractionDigits,
                maximumFractionDigits: 2
            )
            return Model(
                tonBalance: formattedBalance,
                fiatBalance: formattedFiatBalance,
                address: try contract.address().toShortString(bounceable: false)
            )
        } catch {
            throw Error.failedToLoad
        }
    }
}
