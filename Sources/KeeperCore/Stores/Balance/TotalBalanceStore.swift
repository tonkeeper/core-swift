import Foundation
import TonSwift
import BigInt

protocol TotalBalanceStoreObserver: AnyObject {
  func didGetTotalBalanceStoreEvent(_ event: TotalBalanceStore.Event)
}

final class TotalBalanceStore {
  
  enum Event {
    case didUpdateTotalBalance(wallet: Wallet, totalBalance: TotalBalance)
  }
  
  var wallets = [Wallet]()
    
  private let balanceStore: BalanceStore
  private let currencyStore: CurrencyStore
  private let ratesStore: RatesStore
  private let totalBalanceService: TotalBalanceService
  
  init(balanceStore: BalanceStore, 
       currencyStore: CurrencyStore,
       ratesStore: RatesStore,
       totalBalanceService: TotalBalanceService) {
    self.balanceStore = balanceStore
    self.currencyStore = currencyStore
    self.ratesStore = ratesStore
    self.totalBalanceService = totalBalanceService
    
    currencyStore.addObserver(self)
    
    Task {
      await balanceStore.addObserver(self)
    }
    Task {
      await ratesStore.addObserver(self)
    }
  }
  
  func getTotalBalance(wallet: Wallet, currency: Currency) -> TotalBalance {
    do {
      return try totalBalanceService.getTotalBalance(
        address: try wallet.address,
        currency: currency
      )
    } catch {
      return TotalBalance(amount: 0, fractionalDigits: 0)
    }
  }
  
  func updateTotalBalance(wallet: Wallet) {
    let currency = currencyStore.getActiveCurrency()
    do {
      let balance = try balanceStore.getBalance(wallet: wallet)
      let rates = ratesStore.getRates(jettons: balance.balance.jettonsBalance.map { $0.item.jettonInfo })
      let totalBalance = totalBalanceService.calculateTotalBalance(
        balance: balance.balance,
        currency: currency,
        rates: rates
      )
      try totalBalanceService.saveTotalBalance(totalBalance: totalBalance, address: wallet.address, currency: currency)
      notifyObservers(
        event: .didUpdateTotalBalance(
          wallet: wallet,
          totalBalance: totalBalance
        )
      )
    } catch {}
  }
  
  struct TotalBalanceStoreObserverWrapper {
    weak var observer: TotalBalanceStoreObserver?
  }
  
  private var observers = [TotalBalanceStoreObserverWrapper]()
  
  func addObserver(_ observer: TotalBalanceStoreObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(TotalBalanceStoreObserverWrapper(observer: observer))
  }
  
  func removeObserver(_ observer: TotalBalanceStoreObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension TotalBalanceStore {
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }

  func notifyObservers(event: TotalBalanceStore.Event) {
    observers.forEach { $0.observer?.didGetTotalBalanceStoreEvent(event) }
  }
}

extension TotalBalanceStore: BalanceStoreObserver {
  func didGetBalanceStoreEvent(_ event: BalanceStore.Event) {
    updateTotalBalance(wallet: event.wallet)
  }
}

extension TotalBalanceStore: RatesStoreObserver {
  func didGetRatesStoreEvent(_ event: RatesStore.Event) {
    switch event {
    case .updateRates(_, let wallet):
      updateTotalBalance(wallet: wallet)
    }
  }
}

extension TotalBalanceStore: CurrencyStoreObserver {
  func didGetCurrencyStoreEvent(_ event: CurrencyStoreEvent) {
    switch event {
    case .didUpdateActiveCurrency:
      wallets.forEach { updateTotalBalance(wallet: $0) }
    }
  }
}
