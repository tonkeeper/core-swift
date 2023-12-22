import Foundation
import TonSwift
import WalletCoreCore

public class BalanceController {
    
    public var didUpdateBalance: ((WalletBalanceModel) -> Void)?
    public var didCheckDateAndTime: ((_ isCorrect: Bool) -> Void)?
    
    public var address: Address? {
        try? walletProvider.activeWallet.address
    }
    
    private let balanceStore: BalanceStore
    private let ratesStore: RatesStore
    private let walletProvider: WalletProvider
    private let walletBalanceMapper: WalletBalanceMapper
    private let dateAndTimeCheckService: DateAndTimeCheckService
    
    private var observingTask: Task<Void, Never>?
    private var isBalanceOutdated = false
    
    init(balanceStore: BalanceStore, 
         ratesStore: RatesStore,
         walletProvider: WalletProvider,
         walletBalanceMapper: WalletBalanceMapper,
         dateAndTimeCheckService: DateAndTimeCheckService) {
        self.balanceStore = balanceStore
        self.ratesStore = ratesStore
        self.walletProvider = walletProvider
        self.walletBalanceMapper = walletBalanceMapper
        self.dateAndTimeCheckService = dateAndTimeCheckService
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
        checkDateAndTime()
    }
    
    public func reload() {
        Task {
            guard await checkIfNeedToReload() else { return }
            balanceStore.reloadBalance()
            ratesStore.reloadRates(tokens: [])
            
        }
        checkDateAndTime()
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
    
    func checkIfNeedToReload() async -> Bool {
        await Task {
            do {
                let state = try balanceStore.balanceState
                guard let seconds = Calendar.current.dateComponents([.second], from: state.date, to: Date()).second else { return true }
                return seconds > 5
            } catch {
                return true
            }
        }
        .value
    }
    
    func checkDateAndTime() {
        Task {
            let serverTimeInterval = try await dateAndTimeCheckService.getTime()
            let localTimeInterval = Date().timeIntervalSince1970
            let isCorrect = abs(localTimeInterval - serverTimeInterval) < 60
            self.didCheckDateAndTime?(isCorrect)
        }
    }
}

extension BalanceController: WalletProviderObserver {
    public func walletProvider(_ walletProvider: WalletProvider, didUpdateActiveWallet wallet: Wallet) {
        Task {
            showBalanceState()
        }
    }
}
