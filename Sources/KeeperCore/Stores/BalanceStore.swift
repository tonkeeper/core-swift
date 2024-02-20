import Foundation
import TonSwift

protocol BalanceStoreObserver: AnyObject {
  func didGetBalanceStoreEvent(_ event: BalanceStore.Event)
}

actor BalanceStore {
  public struct Event {
    public let address: Address
    public let result: Result<WalletBalance, Swift.Error>
  }
  
  private var tasksInProgress = [Address: Task<(), Never>]()
  
  private let balanceService: BalanceService
  
  init(balanceService: BalanceService) {
    self.balanceService = balanceService
  }
  
  func loadBalance(address: Address) {
    if let taskInProgress = tasksInProgress[address] {
      taskInProgress.cancel()
      tasksInProgress[address] = nil
    }
    
    let task = Task {
      let event: Event
      do {
        let walletBalance = try await balanceService.loadWalletBalance(address: address)
        event = Event(address: address, result: .success(walletBalance))
      } catch {
        event = Event(address: address, result: .failure(error))
      }
      guard !Task.isCancelled else { return }
      notifyObservers(event: event)
      tasksInProgress[address] = nil
    }
    tasksInProgress[address] = task
  }
  
  func loadBalances(addresses: [Address]) {
    addresses.forEach { address in
      loadBalance(address: address)
    }
  }
  
  func getBalance(address: Address) throws -> WalletBalance {
    return try balanceService.getBalance(address: address)
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
