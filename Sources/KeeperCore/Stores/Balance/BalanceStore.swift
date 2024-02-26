import Foundation
import TonSwift

protocol BalanceStoreObserver: AnyObject {
  func didGetBalanceStoreEvent(_ event: BalanceStore.Event)
}

actor BalanceStore {
  public struct Event {
    public let wallet: Wallet
    public let result: Result<WalletBalance, Swift.Error>
  }
  
  private var tasksInProgress = [Wallet: Task<(), Swift.Error>]()
  
  private let balanceService: BalanceService
  
  init(balanceService: BalanceService) {
    self.balanceService = balanceService
  }
  
  func loadBalance(wallet: Wallet) {
    if let taskInProgress = tasksInProgress[wallet] {
      taskInProgress.cancel()
      tasksInProgress[wallet] = nil
    }
    
    let task = Task {
      let address = try wallet.address
      let event: Event
      do {
        let walletBalance = try await balanceService.loadWalletBalance(address: address)
        event = Event(wallet: wallet, result: .success(walletBalance))
      } catch {
        event = Event(wallet: wallet, result: .failure(error))
      }
      guard !Task.isCancelled else { return }
      notifyObservers(event: event)
      tasksInProgress[wallet] = nil
    }
    tasksInProgress[wallet] = task
  }
  
  func loadBalances(wallets: [Wallet]) {
    wallets.forEach { loadBalance(wallet: $0) }
  }
  
  nonisolated
  func getBalance(wallet: Wallet) throws -> WalletBalance {
    return try balanceService.getBalance(address: wallet.address)
  }
    
  struct BalanceStoreObserverWrapper {
    weak var observer: BalanceStoreObserver?
  }
  
  private var observers = [BalanceStoreObserverWrapper]()
  
  func addObserver(_ observer: BalanceStoreObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(BalanceStoreObserverWrapper(observer: observer))
  }
  
  func removeObserver(_ observer: BalanceStoreObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension BalanceStore {
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }

  func notifyObservers(event: BalanceStore.Event) {
    observers.forEach { $0.observer?.didGetBalanceStoreEvent(event) }
  }
}
