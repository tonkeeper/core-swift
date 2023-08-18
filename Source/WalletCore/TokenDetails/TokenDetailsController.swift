//
//  TokenDetailsController.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation

public protocol TokenDetailsTonControllerOutput: AnyObject {
    func handleTonRecieve()
    func handleTonSend()
    func handleTonSwap()
    func handleTonBuy()
}

public protocol TokenDetailsTokenControllerOutput: AnyObject {
    func handleTokenRecieve(tokenInfo: TokenInfo)
    func handleTokenSend(tokenInfo: TokenInfo)
    func handleTokenSwap(tokenInfo: TokenInfo)
}

public typealias TokenDetailsControllerOutput = TokenDetailsTonControllerOutput & TokenDetailsTokenControllerOutput

public final class TokenDetailsController {
    
    public weak var output: TokenDetailsControllerOutput? {
        didSet {
            tokenDetailsProvider.output = output
        }
    }
    
    public struct TokenDetailsHeader {
        public enum Button {
            case send
            case receive
            case buy
            case swap
        }
        
        public let name: String
        public let amount: String
        public let fiatAmount: String?
        public let price: String?
        public let image: Image
        public let buttons: [Button]
    }
    
    private var tokenDetailsProvider: TokenDetailsProvider
    private let walletProvider: WalletProvider
    private let balanceService: WalletBalanceService
    
    init(tokenDetailsProvider: TokenDetailsProvider,
         walletProvider: WalletProvider,
         balanceService: WalletBalanceService) {
        self.tokenDetailsProvider = tokenDetailsProvider
        self.walletProvider = walletProvider
        self.balanceService = balanceService
    }
    
    public func getTokenHeader() throws -> TokenDetailsHeader {
        let wallet = try walletProvider.activeWallet
        
        let walletBalance: WalletBalance
        do {
            walletBalance = try balanceService.getWalletBalance(wallet: wallet)
        } catch {
            walletBalance = try balanceService.getEmptyWalletBalance(wallet: wallet)
        }
        return tokenDetailsProvider.getHeader(walletBalance: walletBalance, currency: .USD)
    }
    
    public func reloadContent() async throws {
        let wallet = try walletProvider.activeWallet
        try await _ = balanceService.loadWalletBalance(wallet: wallet)
        try await tokenDetailsProvider.reloadRate(currency: .USD)
    }
    
    public func handleRecieve() {
        tokenDetailsProvider.handleRecieve()
    }
    
    public func handleSend() {
        tokenDetailsProvider.handleSend()
    }
    
    public func handleSwap() {
        tokenDetailsProvider.handleSwap()
    }
    
    public func handleBuy() {
        tokenDetailsProvider.handleBuy()
    }
    
    public func hasChart() -> Bool {
        tokenDetailsProvider.hasChart
    }
    
    public var hasAbout: Bool {
        tokenDetailsProvider.hasAbout
    }
}
