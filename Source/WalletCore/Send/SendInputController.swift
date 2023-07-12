//
//  SendInputController.swift
//  
//
//  Created by Grigory on 5.7.23..
//

import Foundation
import TonSwift
import BigInt

public struct TokenListModel {
    public struct TokenModel {
        public let icon: Image
        public let code: String?
        public let amount: String?
    }
    public let tokens: [TokenModel]
    public let selectedIndex: Int
}

public struct TokenTransfer {
    public enum Token {
        case ton
        case token(Address)
    }
    
    public let token: Token
    public let amount: BigInt
}

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
            var token: Token = .ton(TonInfo())
            var amount: BigInt
        }
        
        var fiatState: FiatState
        var tokenState: TokenState
        var active: Active
        
        var inputMaximumFractionDigits: Int {
            switch active {
            case .fiat:
                return .fiatMaximumFractionalLength
            case .token:
                return tokenState.token.fractionalDigits
            }
        }
        
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
        
        mutating func updateToken(token: Token) {
            tokenState.token = token
            resetAmount()
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
    public var didChangeToken: ((_ code: String?) -> Void)?
    
    private let bigIntAmountFormatter: BigIntAmountFormatter
    private let ratesService: RatesService
    private let balanceService: WalletBalanceService
    private let tokenMapper: SendTokenMapper
    private let walletProvider: WalletProvider
    private let rateConverter: RateConverter
    
    private var state = State(fiatState: .init(amount: 0, fractionalDigits: 0), tokenState: .init(amount: 0), active: .token)
    public private(set) var isMax = false
    private var tokensBalances = [TokenBalance]()
    
    init(bigIntAmountFormatter: BigIntAmountFormatter,
         ratesService: RatesService,
         balanceService: WalletBalanceService,
         tokenMapper: SendTokenMapper,
         walletProvider: WalletProvider,
         rateConverter: RateConverter) {
        self.bigIntAmountFormatter = bigIntAmountFormatter
        self.ratesService = ratesService
        self.balanceService = balanceService
        self.tokenMapper = tokenMapper
        self.walletProvider = walletProvider
        self.rateConverter = rateConverter
    }
    
    public var tokenTransferData: TokenTransfer? {
        switch state.tokenState.token {
        case .ton:
            return TokenTransfer(token: .ton, amount: state.tokenState.amount)
        case .token(let tokenInfo):
            guard let wallet = try? walletProvider.activeWallet,
                  let walletBalance = try? balanceService.getWalletBalance(wallet: wallet),
                  let tokenBalance = walletBalance.tokensBalance.first(where: { $0.amount.tokenInfo == tokenInfo }) else {
                return nil
            }
            return TokenTransfer(token: .token(tokenBalance.walletAddress), amount: state.tokenState.amount)
        }
    }
    
    public func setInitialState() {
        update()
    }
    
    public func didChangeInput(string: String?) {
        defer {
            updateAvailability()
        }
        isMax = false
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
        if isMax, let activeTokenBalanceInfo = activeTokenBalanceInfo() {
            state.updateTokenAmount(activeTokenBalanceInfo.balance)
            if let fiatAmount = convertTokenAmount(amount: activeTokenBalanceInfo.balance,
                                                   fractionalDigits: activeTokenBalanceInfo.fractionalDigits) {
                state.updateFiatAmount(fiatAmount.amount, fractionalDigits: fiatAmount.fractionLength)
            }
        } else {
            state.updateTokenAmount(0)
            state.updateFiatAmount(0, fractionalDigits: 0)
        }
        
        update()
    }
    
    public func didSelectToken(at index: Int) throws {
        isMax = false
        switch index {
        case 0:
            let tonInfo = TonInfo()
            state.updateToken(token: .ton(tonInfo))
        default:
            let wallet = try walletProvider.activeWallet
            let walletBalance = try balanceService.getWalletBalance(wallet: wallet)
            let token = walletBalance.tokensBalance[index - 1]
            state.updateToken(token: .token(token.amount.tokenInfo))
        }
        update()
    }
    
    public func tokenListModel() -> TokenListModel {
        do {
            let wallet = try walletProvider.activeWallet
            let walletBalance = try balanceService.getWalletBalance(wallet: wallet)
            
            var models = [TokenListModel.TokenModel]()
            models.append(tokenMapper.mapTon(tonBalance: walletBalance.tonBalance))
            models.append(contentsOf: walletBalance.tokensBalance.map { token in
                tokenMapper.mapToken(tokenBalance: token)
            })
            
            let selectedIndex: Int
            switch state.tokenState.token {
            case .ton:
                selectedIndex = 0
            case let .token(tokenInfo):
                selectedIndex = (walletBalance.tokensBalance
                    .firstIndex(where: { $0.amount.tokenInfo == tokenInfo }) ?? 0) + 1
            }
            
            return TokenListModel(tokens: models, selectedIndex: selectedIndex)
        } catch {
            return TokenListModel(tokens: [], selectedIndex: 0)
        }
    }
    
    func update() {
        defer {
            updateAvailability()
            try? updateTokenSelection()
        }
        
        didChangeInputMaximumFractionLength?(state.inputMaximumFractionDigits)
        
        let tokenAmount = bigIntAmountFormatter.format(
            amount: state.tokenState.amount,
            fractionDigits: state.tokenState.token.fractionalDigits,
            maximumFractionDigits: state.inputMaximumFractionDigits,
            symbol: nil)
        let fiatAmount = bigIntAmountFormatter.format(
            amount: state.fiatState.amount,
            fractionDigits: state.fiatState.fractionalDigits,
            maximumFractionDigits: .fiatMaximumFractionalLength,
            symbol: nil)
        
        switch state.active {
        case .token:
            updateTokenActive(tokenAmount: tokenAmount, fiatAmount: fiatAmount)
        case .fiat:
            updateFiatActive(tokenAmount: tokenAmount, fiatAmount: fiatAmount)
        }
    }
    
    func updateTokenActive(tokenAmount: String, fiatAmount: String) {
        didUpdateActiveAmount?(tokenAmount, state.tokenState.token.code)
        didUpdateInactiveAmount?(fiatAmount + " " + state.fiatState.fiat.code)
    }
    
    func updateFiatActive(tokenAmount: String, fiatAmount: String) {
        didUpdateActiveAmount?(fiatAmount, state.fiatState.fiat.code)
        var amountString = tokenAmount
        if let code = state.tokenState.token.code {
            amountString += " " + code
        }
        didUpdateInactiveAmount?(amountString)
    }
    
    func updateTokenSelection() throws {
        let wallet = try walletProvider.activeWallet
        let walletBalance = try balanceService.getWalletBalance(wallet: wallet)
        if walletBalance.tokensBalance.isEmpty {
            didChangeToken?(nil)
        } else {
            didChangeToken?(state.tokenState.token.code)
        }
    }
    
    func updateAvailability() {
        guard let activeTokenBalanceInfo = activeTokenBalanceInfo() else {
            return
        }
        let available = activeTokenBalanceInfo.balance - state.tokenState.amount
        
        let isContinueAvailable = (available >= 0) && !state.tokenState.amount.isZero
        didUpdateContinueButtonAvailability?(isContinueAvailable)
        
        let resultString: String
        let isInsufficient: Bool

        if available >= 0 {
            let tokenOneAmount = BigInt(stringLiteral: "1" + String(repeating: "0", count: activeTokenBalanceInfo.fractionalDigits))
            let maximumFractionDigits = available < tokenOneAmount
            ? activeTokenBalanceInfo.fractionalDigits
            : .inactiveMaximumFractionalLength
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
    
    func activeTokenBalanceInfo() -> (balance: BigInt, fractionalDigits: Int, code: String?)? {
        do {
            let wallet = try walletProvider.activeWallet
            let balance = try balanceService.getWalletBalance(wallet: wallet)
            switch state.tokenState.token {
            case .ton:
                return (BigInt(integerLiteral: balance.tonBalance.amount.quantity),
                        balance.tonBalance.amount.tonInfo.fractionDigits,
                        balance.tonBalance.amount.tonInfo.symbol)
            case .token(let tokenInfo):
                guard let balanceToken = balance.tokensBalance.first(where: { $0.amount.tokenInfo == tokenInfo }) else {
                    return nil
                }
                return (balanceToken.amount.quantity,
                        tokenInfo.fractionDigits,
                        tokenInfo.symbol)
            }
        } catch {
            return nil
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
