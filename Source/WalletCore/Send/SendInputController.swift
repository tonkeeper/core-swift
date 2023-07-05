//
//  SendInputController.swift
//  
//
//  Created by Grigory on 5.7.23..
//

import Foundation
import BigInt

public final class SendInputController {
    
    enum Token {
        case ton(TonInfo)
        case token(TokenInfo)
        
        var fractionalDigits: Int {
            switch self {
            case let .ton(tonInfo):
                return tonInfo.fractionDigits
            case let .token(token):
                return token.fractionDigits
            }
        }
        
        var code: String? {
            switch self {
            case let .ton(tonInfo):
                return tonInfo.symbol
            case let .token(token):
                return token.symbol
            }
        }
    }
    
    struct State {
        enum Active {
            case token
            case fiat
        }
        
        struct FiatState {
            let fiat: Currency = .USD
            var amount: BigInt
            var fractionalDigits: Int
        }
        
        struct TokenState {
            let token: Token = .ton(TonInfo())
            var amount: BigInt
        }
        
        var fiatState: FiatState
        var tokenState: TokenState
        var active: Active
        
        mutating func toggleActive() {
            switch active {
            case .fiat:
                self.active = .token
            case .token:
                self.active = .fiat
            }
        }
        
        mutating func updateTokenAmount(_ amount: BigInt) {
            tokenState.amount = amount
        }
        
        mutating func updateFiatAmount(_ amount: BigInt, fractionalDigits: Int) {
            fiatState.amount = amount
            fiatState.fractionalDigits = fractionalDigits
        }
        
        mutating func resetAmount() {
            tokenState.amount = 0
            fiatState.amount = 0
            fiatState.fractionalDigits = 0
        }
    }
    
    public var didChangeInputMaximumFractionLength: ((_ length: Int) -> Void)?
    public var didUpdateInactiveAmount: ((_ amount: String?) -> Void)?
    public var didUpdateActiveAmount: ((_ amount: String?, _ code: String?) -> Void)?
    public var didUpdateAvailableBalance: ((_ availableBalance: String, _ isInsufficient: Bool) -> Void)?
    public var didUpdateContinueButtonAvailability: ((_ isAvailable: Bool) -> Void)?
    
    private let bigIntAmountFormatter: BigIntAmountFormatter
    private let ratesService: RatesService
    private let balanceService: WalletBalanceService
    private let balanceMapper: WalletBalanceMapper
    private let walletProvider: WalletProvider
    private let rateConverter: RateConverter
    
    private var state = State(fiatState: .init(amount: 0, fractionalDigits: 0), tokenState: .init(amount: 0), active: .token)
    public private(set) var isMax = false
    
    init(bigIntAmountFormatter: BigIntAmountFormatter,
         ratesService: RatesService,
         balanceService: WalletBalanceService,
         balanceMapper: WalletBalanceMapper,
         walletProvider: WalletProvider,
         rateConverter: RateConverter) {
        self.bigIntAmountFormatter = bigIntAmountFormatter
        self.ratesService = ratesService
        self.balanceService = balanceService
        self.balanceMapper = balanceMapper
        self.walletProvider = walletProvider
        self.rateConverter = rateConverter
        
        didUpdateActiveAmount?("0", state.tokenState.token.code)
    }
    
    public func setInitialState() {
        update()
    }
    
    public func didChangeInput(string: String?) {
        defer {
            updateContinueAvailableState()
            try? updateAvailableBalance()
        }
        
        guard let string = string,
        !string.isEmpty else {
            didUpdateInactiveAmount?("0 \(state.fiatState.fiat.code)")
            state.resetAmount()
            return
        }
        switch state.active {
        case .token:
            try? handleInputToken(input: string)
        case .fiat:
            try? handleInputFiat(input: string)
        }
    }
    
    public func toggleActive() {
        state.toggleActive()
        update()
    }
    
    public func toggleMax() throws {
        isMax.toggle()
        if isMax {
            let wallet = try walletProvider.activeWallet
            let walletBalance = try balanceService.getWalletBalance(wallet: wallet)
            let tonBalance = BigInt(integerLiteral: walletBalance.tonBalance.amount.quantity)
            state.updateTokenAmount(tonBalance)
            if let fiatAmount = convertTokenAmount(amount: tonBalance, fractionalDigits: walletBalance.tonBalance.amount.tonInfo.fractionDigits) {
                state.updateFiatAmount(fiatAmount.amount, fractionalDigits: fiatAmount.fractionLength)
            }
        } else {
            state.updateTokenAmount(0)
            state.updateFiatAmount(0, fractionalDigits: 0)
        }
        
        update()
        try updateAvailableBalance()
    }
    
    func handleInputToken(input: String) throws {
        let (amount, fractionalDigits) = try bigIntAmountFormatter.bigInt(
            string: input,
            targetFractionalDigits: state.tokenState.token.fractionalDigits
        )
    
        state.updateTokenAmount(amount)
        if let fiatAmount = convertTokenAmount(amount: amount, fractionalDigits: fractionalDigits) {
            state.updateFiatAmount(fiatAmount.amount, fractionalDigits: fiatAmount.fractionLength)
            let formatted = bigIntAmountFormatter.format(
                amount: fiatAmount.amount,
                fractionDigits: fiatAmount.fractionLength,
                maximumFractionDigits: .fiatMaximumFractionalLength,
                symbol: nil)
            
            self.didUpdateInactiveAmount?(formatted + " " + state.fiatState.fiat.code)
        }
    }
    
    func handleInputFiat(input: String) throws {
        let (amount, fractionalDigits) = try bigIntAmountFormatter.bigInt(
            string: input,
            targetFractionalDigits: .fiatMaximumFractionalLength
        )
        
        state.updateFiatAmount(amount, fractionalDigits: fractionalDigits)
        
        if let convertedAmount = convertFiatAmount(amount: amount, fractionalDigits: fractionalDigits) {
            let fractionalDiff = convertedAmount.fractionLength - state.tokenState.token.fractionalDigits
            let tokenAmount = convertedAmount.amount.shortBigInt(to: fractionalDiff)

            state.updateTokenAmount(tokenAmount)

            let formatted = bigIntAmountFormatter.format(
                amount: tokenAmount,
                fractionDigits: state.tokenState.token.fractionalDigits,
                maximumFractionDigits: .inactiveMaximumFractionalLength,
                symbol: nil)
            var amountString = formatted
            if let code = state.tokenState.token.code {
                amountString += " " + code
            }
            didUpdateInactiveAmount?(amountString)
        }
    }
    
    func convertTokenAmount(amount: BigInt, fractionalDigits: Int) -> (amount: BigInt, fractionLength: Int)?  {
        guard let rate = getTokenRate() else { return nil }
        return rateConverter.convert(amount: amount, amountFractionLength: fractionalDigits, rate: rate)
    }
    
    func convertFiatAmount(amount: BigInt, fractionalDigits: Int) -> (amount: BigInt, fractionLength: Int)?  {
        guard let rate = getTokenRate() else { return nil }
        let reversedRate = Rates.Rate(currency: rate.currency, rate: 1/rate.rate)
        return rateConverter.convert(amount: amount, amountFractionLength: fractionalDigits, rate: reversedRate)
    }
    
    func update() {
        defer {
            updateContinueAvailableState()
            try? updateAvailableBalance()
        }
        
        let tokenMaximumFractionDigits: Int
        switch state.active {
        case .token:
            tokenMaximumFractionDigits = state.tokenState.token.fractionalDigits
        case .fiat:
            tokenMaximumFractionDigits = .fiatMaximumFractionalLength
        }
        didChangeInputMaximumFractionLength?(tokenMaximumFractionDigits)
        
        let tokenAmount = bigIntAmountFormatter.format(
            amount: state.tokenState.amount,
            fractionDigits: state.tokenState.token.fractionalDigits,
            maximumFractionDigits: tokenMaximumFractionDigits,
            symbol: nil)
        let fiatAmount = bigIntAmountFormatter.format(
            amount: state.fiatState.amount,
            fractionDigits: state.fiatState.fractionalDigits,
            maximumFractionDigits: .fiatMaximumFractionalLength,
            symbol: nil)
        switch state.active {
        case .token:
            didUpdateActiveAmount?(tokenAmount, state.tokenState.token.code)
            didUpdateInactiveAmount?(fiatAmount + " " + state.fiatState.fiat.code)
        case .fiat:
            didUpdateActiveAmount?(fiatAmount, state.fiatState.fiat.code)
            var amountString = tokenAmount
            if let code = state.tokenState.token.code {
                amountString += " " + code
            }
            didUpdateInactiveAmount?(amountString)
        }
    }
    
    func updateAvailableBalance() throws {
        let wallet = try walletProvider.activeWallet
        let walletBalance = try balanceService.getWalletBalance(wallet: wallet)
        let tonBalance = BigInt(integerLiteral: walletBalance.tonBalance.amount.quantity)
        let available = tonBalance - state.tokenState.amount
        let resultString: String
        let isInsufficient: Bool
        if available >= 0 {
            let maximumFractionDigits: Int
            if available < BigInt(stringLiteral: "1" + String(repeating: "0", count: state.tokenState.token.fractionalDigits)) {
                maximumFractionDigits = state.tokenState.token.fractionalDigits
            } else {
                maximumFractionDigits = .inactiveMaximumFractionalLength
            }
            let formattedBalance = bigIntAmountFormatter.format(
                amount: available,
                fractionDigits: state.tokenState.token.fractionalDigits,
                maximumFractionDigits: maximumFractionDigits,
                symbol: nil
            )
            let codeString = state.tokenState.token.code ?? ""
            resultString = "Remaining: \(formattedBalance) \(codeString)"
            isInsufficient = false
        } else {
            resultString = "Insufficient balance"
            isInsufficient = true
        }
        didUpdateAvailableBalance?(resultString, isInsufficient)
    }
    
    func updateContinueAvailableState() {
        didUpdateContinueButtonAvailability?(!state.tokenState.amount.isZero)
    }
}

private extension SendInputController {
    func getTokenRate() -> Rates.Rate? {
        guard let rates = try? ratesService.getRates() else { return nil }
        
        switch state.tokenState.token {
        case .ton:
            return rates.ton.first(where: { $0.currency == state.fiatState.fiat })
        case let .token(tokenInfo):
            return rates.tokens.first(where: {
                tokenInfo == $0.tokenInfo
            })?.rates
                .first(where: { $0.currency == state.fiatState.fiat })
        }
    }
}

private extension BigInt {
    func shortBigInt(to count: Int) -> BigInt {
        let divider = BigInt(stringLiteral: "1" + String(repeating: "0", count: count))
        let newValue = self / divider
        return newValue
    }
}

private extension Int {
    static let fiatMaximumFractionalLength = 2
    static let inactiveMaximumFractionalLength = 2
}
