import Foundation
import TonSwift

actor HistoryListPaginator {
  
  enum Event {
    case didGetCachedEvents(AccountEvents)
    case startLoading
    case noEvents
    case didLoadEvents(AccountEvents)
    case startPageLoading
    case pageLoadingFailed
  }
  
  var didSendEvent: ((Event) -> Void)?
  
  // MARK: - State
  
  enum State {
    case idle
    case isLoading(task: Task<(AccountEvents), Swift.Error>)
  }
  
  private let limit = 25
  private var nextFrom: Int64?
  private var state: State = .idle
  
  // MARK: - Dependencies
  
  private let loader: HistoryListLoader
  private let address: Address
  
  // MARK: - Init
  
  init(loader: HistoryListLoader,
       address: Address,
       didSendEvent: ((Event) -> Void)?) {
    self.loader = loader
    self.address = address
    self.didSendEvent = didSendEvent
  }
  
  // MARK: - Logic
  
  func startLoading() async throws {
    do {
      let cachedEvents = try loader.cachedEvents(address: address)
      didSendEvent?(.didGetCachedEvents(cachedEvents))
    } catch {
      didSendEvent?(.startLoading)
    }
  
    do {
      let nextEvents = try await loadNextEvents()
      state = .idle
      if nextEvents.events.isEmpty {
        didSendEvent?(.noEvents)
      } else {
        didSendEvent?(.didLoadEvents(nextEvents))
      }
    } catch {
      didSendEvent?(.noEvents)
    }
  }
  
  func loadNext() async {
    switch state {
    case .isLoading:
      return
    case .idle:
      guard nextFrom != 0 else { return }
      didSendEvent?(.startPageLoading)
      do {
        let nextEvents = try await loadNextEvents()
        didSendEvent?(.didLoadEvents(nextEvents))
      } catch {
        didSendEvent?(.pageLoadingFailed)
      }
      state = .idle
    }
  }
  
  private func loadNextEvents() async throws -> AccountEvents {
    let task: Task<AccountEvents, Swift.Error> = Task {
      let loadedEvents = try await loader.loadEvents(
        address: address,
        beforeLt: nextFrom,
        limit: limit
      )
      try Task.checkCancellation()
      self.nextFrom = loadedEvents.nextFrom
      return loadedEvents
    }
    state = .isLoading(task: task)
    let events = try await task.value
    if events.events.isEmpty && events.nextFrom != 0 {
      return try await loadNextEvents()
    }
    return events
  }
}
