import Foundation

public final class WalletBalanceController {
  
  public var didUpdateBalance: ((WalletBalanceModel) -> Void)?
  
  public var address: String {
    do {
      return try wallet.address.toShortString(bounceable: false)
    } catch {
      return " "
    }
  }

  private var wallet: Wallet
  private let balanceStore: BalanceStore
  private let ratesStore: RatesStore
  private let walletBalanceMapper: WalletBalanceMapper
  
  private var storesObservationTask: Task<Void, Never>?
  
  init(wallet: Wallet,
       balanceStore: BalanceStore,
       ratesStore: RatesStore,
       walletBalanceMapper: WalletBalanceMapper) {
    self.wallet = wallet
    self.balanceStore = balanceStore
    self.ratesStore = ratesStore
    self.walletBalanceMapper = walletBalanceMapper
    startStoresObservation()
  }
  
  public func setWallet(_ wallet: Wallet) {
    self.wallet = wallet
    loadBalance()
  }
  
  public func loadBalance() {
    updateBalance()
    Task {
      try await self.balanceStore.loadBalance(address: self.wallet.address)
    }
  }
  
  public func reloadBalance() {
    Task {
      try await balanceStore.loadBalance(address: wallet.address)
    }
  }
}

private extension WalletBalanceController {
  func didReceiveBalanceUpdateEvent(_ event: Result<BalanceStore.Event, Swift.Error>) {
    switch event {
    case .success(let event):
      updateBalance()
      Task {
        await ratesStore.loadRates(jettons: event.balance.balance.jettonsBalance.map { $0.amount.jettonInfo })
      }
    case .failure(let error):
      // show error
      print(error)
    }
  }
  
  func didReceiveRatesUpdateEvent() {
    updateBalance()
  }
  
  func updateBalance() {
    Task {
      let balanceModel: WalletBalanceModel
      do {
        let walletBalance = try await balanceStore.getBalance(address: try wallet.address)
        let rates = await ratesStore.getRates(jettons: walletBalance.balance.jettonsBalance.map { $0.amount.jettonInfo })
        balanceModel = walletBalanceMapper.mapBalance(
          walletBalance: walletBalance,
          rates: rates,
          currency: .USD
        )
      } catch {
        balanceModel = WalletBalanceModel(total: "-", items: [])
      }
      didUpdateBalance?(balanceModel)
    }
  }
  
  func startStoresObservation() {
    Task {
      await balanceStore.addObserver(self)
    }
    Task {
      await ratesStore.addObserver(self)
    }
  }
}

extension WalletBalanceController: BalanceStoreObserver {
  func didGetBalanceStoreEvent(_ event: Result<BalanceStore.Event, Error>) {
    didReceiveBalanceUpdateEvent(event)
  }
}

extension WalletBalanceController: RatesStoreObserver {
  func didGetRatesStoreEvent(_ event: RatesStore.Event) {
    switch event {
    case .updateRates:
      didReceiveRatesUpdateEvent()
    }
  }
}
