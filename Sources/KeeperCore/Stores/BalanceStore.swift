import Foundation
import TonSwift

actor BalanceStore {
  typealias Stream = AsyncStream<Result<Event, Swift.Error>>
  
  struct Event {
    let address: Address
    let balance: WalletBalance
  }
  
  private var continuations = [UUID: Stream.Continuation]()
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
        continuations.values.forEach { $0.yield(.success(event)) }
        tasksInProgress[address] = nil
      } catch {
        guard !Task.isCancelled else { return }
        continuations.values.forEach { $0.yield(.failure(error)) }
        tasksInProgress[address] = nil
      }
    }
    tasksInProgress[address] = task
  }
  
  func updateStream() -> Stream {
    createUpdateStream()
  }
}

private extension BalanceStore {
  func createUpdateStream() -> Stream {
    let uuid = UUID()
    return Stream { continuation in
      self.continuations[uuid] = continuation
      continuation.onTermination = { [weak self] termination in
        guard let self = self else { return }
        Task {
          await self.removeUpdateStreamContinuation(with: uuid)
        }
      }
    }
  }
  
  func removeUpdateStreamContinuation(with uuid: UUID) {
    self.continuations.removeValue(forKey: uuid)
  }
}
