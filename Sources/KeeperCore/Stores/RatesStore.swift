import Foundation

protocol RatesStoreObserver: AnyObject {
  func didGetRatesStoreEvent(_ event: RatesStore.Event)
}

actor RatesStore {
  
  enum Event {
    case updateRates
  }
  
  private let ratesService: RatesService
  
  init(ratesService: RatesService) {
    self.ratesService = ratesService
  }
  
  func loadRates(jettons: [JettonInfo]) {
    Task {
      _ = try await ratesService.loadRates(
        jettons: jettons,
        currencies: Currency.allCases
      )
      notifyObservers(event: .updateRates)
    }
  }
  
  func getRates(jettons: [JettonInfo]) -> Rates {
    return ratesService.getRates(jettons: jettons)
  }
  
  struct RatesStoreObserverWrapper {
    weak var observer: RatesStoreObserver?
  }
  
  private var observers = [RatesStoreObserverWrapper]()
  
  func addObserver(_ observer: RatesStoreObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(RatesStoreObserverWrapper(observer: observer))
  }
  
  func removeObserver(_ observer: RatesStoreObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension RatesStore {
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }

  func notifyObservers(event: RatesStore.Event) {
    observers.forEach { $0.observer?.didGetRatesStoreEvent(event) }
  }
}
