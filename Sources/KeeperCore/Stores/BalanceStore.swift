import Foundation
import TonSwift

 
protocol BalanceStoreObserver: AnyObject {
  func didGetBalanceStoreEvent(_ event: Result<BalanceStore.Event, Swift.Error>)
}

actor BalanceStore {
  typealias Stream = AsyncStream<Result<Event, Swift.Error>>
  
  public struct Event {
    public let address: Address
    public let balance: WalletBalance
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
      do {
        let walletBalance = try await balanceService.loadWalletBalance(address: address)
        let event = Event(address: address, balance: walletBalance)
        guard !Task.isCancelled else { return }
        notifyObservers(event: .success(event))
        tasksInProgress[address] = nil
      } catch {
        guard !Task.isCancelled else { return }
        notifyObservers(event: .failure(error))
        tasksInProgress[address] = nil
      }
    }
    tasksInProgress[address] = task
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

  func notifyObservers(event: Result<BalanceStore.Event, Swift.Error>) {
    observers.forEach { $0.observer?.didGetBalanceStoreEvent(event) }
  }
}
