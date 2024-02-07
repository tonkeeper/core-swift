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
  private let currencyStore: CurrencyStore
  private let walletBalanceMapper: WalletBalanceMapper
  
  private var storesObservationTask: Task<Void, Never>?
  
  init(wallet: Wallet,
       balanceStore: BalanceStore,
       ratesStore: RatesStore,
       currencyStore: CurrencyStore,
       walletBalanceMapper: WalletBalanceMapper) {
    self.wallet = wallet
    self.balanceStore = balanceStore
    self.ratesStore = ratesStore
    self.currencyStore = currencyStore
    self.walletBalanceMapper = walletBalanceMapper
    startStoresObservation()
  }

  public func loadBalance() {
    updateBalance()
    Task {
      try await self.balanceStore.loadBalance(address: self.wallet.address)
    }
  }
}

private extension WalletBalanceController {
  func didReceiveBalanceUpdateEvent(_ event: BalanceStore.Event) {
    guard let address = try? wallet.address, event.address == address else { return }
    switch event.result {
    case .success:
      updateBalance()
    case .failure(let error):
      // show error
      print(error)
    }
  }
  
  func didReceiveRatesUpdateEvent() {
    updateBalance()
  }
  
  func updateBalance() {
    let currency = currencyStore.getActiveCurrency()
    Task {
      let balanceModel: WalletBalanceModel
      do {
        let walletBalance = try await balanceStore.getBalance(address: try wallet.address)
        let rates = await ratesStore.getRates(jettons: walletBalance.balance.jettonsBalance.map { $0.amount.jettonInfo })
        balanceModel = walletBalanceMapper.mapBalance(
          walletBalance: walletBalance,
          rates: rates,
          currency: currency
        )
      } catch {
        balanceModel = WalletBalanceModel(total: "-", items: [])
      }
      didUpdateBalance?(balanceModel)
    }
  }
  
  func startStoresObservation() {
    currencyStore.addObserver(self)
    Task {
      await balanceStore.addObserver(self)
    }
    Task {
      await ratesStore.addObserver(self)
    }
  }
}

extension WalletBalanceController: BalanceStoreObserver {
  func didGetBalanceStoreEvent(_ event: BalanceStore.Event) {
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

extension WalletBalanceController: CurrencyStoreObserver {
  func didGetCurrencyStoreEvent(_ event: CurrencyStoreEvent) {
    updateBalance()
  }
}
