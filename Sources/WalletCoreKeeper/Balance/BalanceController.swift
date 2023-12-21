import Foundation
import TonSwift
import WalletCoreCore

public class BalanceController {
    
    public var didUpdateBalance: ((WalletBalanceModel) -> Void)?
    
    public var address: Address? {
        try? walletProvider.activeWallet.address
    }
    
    private let balanceStore: BalanceStore
    private let ratesStore: RatesStore
    private let walletProvider: WalletProvider
    private let walletBalanceMapper: WalletBalanceMapper
    
    private var observingTask: Task<Void, Never>?
    private var isBalanceOutdated = false
    
    init(balanceStore: BalanceStore, 
         ratesStore: RatesStore,
         walletProvider: WalletProvider,
         walletBalanceMapper: WalletBalanceMapper) {
        self.balanceStore = balanceStore
        self.ratesStore = ratesStore
        self.walletProvider = walletProvider
        self.walletBalanceMapper = walletBalanceMapper
        startStoresObservation()
        walletProvider.addObserver(self)
    }
    
    deinit {
        stopStoresObservation()
    }
    
    public func load() {
        showBalanceState()
        balanceStore.reloadBalance()
        ratesStore.reloadRates(tokens: [])
    }
    
    public func reload() {
        balanceStore.reloadBalance()
        ratesStore.reloadRates(tokens: [])
    }
}

private extension BalanceController {
    func startStoresObservation() {
        let balanceStoreStream = balanceStore.updateStream()
        let ratesStoreStream = ratesStore.updateStream()
        self.observingTask = Task {
            Task {
                for await event in balanceStoreStream {
                    didReceiveBalanceStoreEvent(event)
                }
            }
            Task {
                for await event in ratesStoreStream {
                    didReceiveRatesStoreEvent(event)
                }
            }
        }
    }
    
    func stopStoresObservation() {
        observingTask?.cancel()
    }
    
    func didReceiveBalanceStoreEvent(_ event: Result<WalletBalanceState, Error>) {
        switch event {
        case .success(let success):
            isBalanceOutdated = false
            showBalanceState()
            loadRates(for: success.balance)
        case .failure:
            isBalanceOutdated = true
            showBalanceState()
        }
    }
    
    func didReceiveRatesStoreEvent(_ event: Result<Rates, Error>) {
        switch event {
        case .success:
            showBalanceState()
        case .failure:
            return
        }
    }
    
    func showBalanceState() {
        let wallet: Wallet
        do {
            wallet = try walletProvider.activeWallet
        } catch {
            return
        }
        
        do {
            let balanceState = try balanceStore.balanceState
            let rates = ratesStore.rates
            let model = walletBalanceMapper.mapBalance(
                balanceState,
                rates: rates,
                currency: wallet.currency,
                isOutdated: isBalanceOutdated)
            didUpdateBalance?(model)
        } catch {
            showEmptyBalanceState()
        }
    }
    
    func showEmptyBalanceState() {
        let wallet: Wallet
        let address: Address
        do {
            wallet = try walletProvider.activeWallet
            address = try wallet.address
        } catch {
            return
        }
        
        let balance = WalletBalance(
            walletAddress: address,
            tonBalance: TonBalance(walletAddress: address, amount: TonAmount(quantity: 0)),
            tokensBalance: [],
            previousRevisionsBalances: [], 
            collectibles: [])
        let state = WalletBalanceState(date: Date(), balance: balance)
        let rates = ratesStore.rates
        let model = walletBalanceMapper.mapBalance(
            state,
            rates: rates,
            currency: wallet.currency,
            isOutdated: false)
        didUpdateBalance?(model)
    }
    
    func loadRates(for walletBalance: WalletBalance)  {
        let tokensInfo = walletBalance.tokensBalance.map { $0.amount.tokenInfo }
        ratesStore.reloadRates(tokens: tokensInfo)
    }
}

extension BalanceController: WalletProviderObserver {
    public func walletProvider(_ walletProvider: WalletProvider, didUpdateActiveWallet wallet: Wallet) {
        Task {
            reload()
        }
    }
}
