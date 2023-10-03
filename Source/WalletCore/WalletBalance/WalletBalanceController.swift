//
//  WalletBalanceController.swift
//
//
//  Created by Grigory on 1.7.23..
//

import Foundation
import TonSwift

public class WalletBalanceController {
    public typealias BalanceModelStream = AsyncStream<WalletBalanceModel>
    public typealias ConnectionStateStream = AsyncStream<WalletBalanceController.State>
    
    public enum State {
        case connecting
        case connected
        case noInternet
        case failed
    }
    
    private let balanceService: WalletBalanceService
    private let ratesService: RatesService
    private let walletProvider: WalletProvider
    private let walletBalanceMapper: WalletBalanceMapper
    private let transactionsUpdatePublishService: TransactionsUpdateService
    
    private var balanceStreamContinuation: BalanceModelStream.Continuation?
    private var connectionStateStreamContinuation: ConnectionStateStream.Continuation?
    
    private var walletAddress: Address {
        get throws {
            let wallet = try walletProvider.activeWallet
            let publicKey = try wallet.publicKey
            let contract = try WalletContractBuilder().walletContract(
                with: publicKey,
                contractVersion: wallet.contractVersion
            )
            let address = try contract.address()
            return address
        }
    }
    
    init(balanceService: WalletBalanceService,
         ratesService: RatesService,
         walletProvider: WalletProvider,
         walletBalanceMapper: WalletBalanceMapper,
         transactionsUpdatePublishService: TransactionsUpdateService) {
        self.balanceService = balanceService
        self.ratesService = ratesService
        self.walletProvider = walletProvider
        self.walletBalanceMapper = walletBalanceMapper
        self.transactionsUpdatePublishService = transactionsUpdatePublishService
        
        walletProvider.addObserver(self)
    }
    
    public func startUpdate() {
        Task {
            guard case .closed = await transactionsUpdatePublishService.state else { return }
            connectionStateStreamContinuation?.yield(.connecting)
            do {
                let loadedBalance = try await loadWalletBalance()
                balanceStreamContinuation?.yield(loadedBalance)
            } catch {
                let controllerState = self.getState(with: .closed(error))
                connectionStateStreamContinuation?.yield(controllerState)
                guard let model = (try? getWalletBalance()) ?? (try? emptyWalletBalance()) else { return }
                balanceStreamContinuation?.yield(model)
                return
            }
            
            let stateStream = await transactionsUpdatePublishService.getStateObservationStream()
            let eventStream = await transactionsUpdatePublishService.getEventStream()
            Task {
                for await state in stateStream {
                    let controllerState = self.getState(with: state)
                    connectionStateStreamContinuation?.yield(controllerState)
                }
            }
            Task {
                for await _ in eventStream {
                    let loadedBalance = try await loadWalletBalance()
                    balanceStreamContinuation?.yield(loadedBalance)
                }
            }
            
            let address = try walletAddress
            await transactionsUpdatePublishService.start(addresses: [address])
        }
    }
    
    public func stopUpdate() {
        Task {
            await transactionsUpdatePublishService.stop()
        }
    }
    
    public func balanceStream() -> BalanceModelStream {
        return BalanceModelStream { continuation in
            balanceStreamContinuation = continuation
            guard let model = (try? getWalletBalance()) ?? (try? emptyWalletBalance()) else { return }
            continuation.yield(model)
        }
    }
    
    public func connectionStateStream() -> ConnectionStateStream {
        return ConnectionStateStream { continuation in
            connectionStateStreamContinuation = continuation
            Task {
                let state = await transactionsUpdatePublishService.state
                connectionStateStreamContinuation?.yield(self.getState(with: state))
            }
        }
    }
    
    public func getWalletBalance() throws -> WalletBalanceModel {
        let wallet = try walletProvider.activeWallet
        let walletBalance = try balanceService.getWalletBalance(wallet: wallet)
        let rates = try ratesService.getRates()
        let walletState = walletBalanceMapper.mapWalletBalance(
            walletBalance,
            rates: rates,
            currency: wallet.currency
        )
        return walletState
    }
    
    func loadWalletBalance() async throws -> WalletBalanceModel {
        let wallet = try walletProvider.activeWallet
        let walletBalance = try await balanceService.loadWalletBalance(wallet: wallet)
        let rates = try await loadRates(walletBalance: walletBalance)
        let walletState = walletBalanceMapper.mapWalletBalance(
            walletBalance,
            rates: rates,
            currency: wallet.currency)
        return walletState
    }
    
    func emptyWalletBalance() throws -> WalletBalanceModel {
        let wallet = try walletProvider.activeWallet
        let walletBalance = try balanceService.getEmptyWalletBalance(wallet: wallet)
        return walletBalanceMapper.mapWalletBalance(
            walletBalance,
            rates: Rates(ton: [], tokens: []),
            currency: wallet.currency)
    }
}

extension WalletBalanceController: WalletProviderObserver {
    public func didUpdateActiveWallet() {
        Task {
            let loadedBalance = try getWalletBalance()
            balanceStreamContinuation?.yield(loadedBalance)
        }
    }
}

private extension WalletBalanceController {
    func loadRates(walletBalance: WalletBalance) async throws -> Rates {
        let tokensInfo = walletBalance.tokensBalance.map { $0.amount.tokenInfo }
        let tonInfo = walletBalance.tonBalance.amount.tonInfo
        return try await ratesService.loadRates(tonInfo: tonInfo,
                                                tokens: tokensInfo,
                                                currencies: Currency.allCases)
    }
    
    func getState(with serviceState: TransactionsUpdateServiceState) -> State {
        switch serviceState {
        case .connecting:
            return .connecting
        case .connected:
            return .connected
        case .closed(let error):
            guard let error = error else {
                return .connecting
            }
            if error.isNoConnectionError {
                return .noInternet
            } else {
                return .failed
            }
        }
    }
}
