//
//  TokenDetailsController.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation

public final class TokenDetailsController {
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
    
    private let tokenDetailsProvider: TokenDetailsProvider
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
        let balance = try balanceService.getWalletBalance(wallet: wallet)
        return tokenDetailsProvider.getHeader(walletBalance: balance, currency: .USD)
    }
    
    public func reloadContent() async throws {
        let wallet = try walletProvider.activeWallet
        try await _ = balanceService.loadWalletBalance(wallet: wallet)
        try await tokenDetailsProvider.reloadRate(currency: .USD)
    }
}
