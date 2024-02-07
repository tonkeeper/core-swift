import Foundation

enum CurrencyStoreEvent {
  case didUpdateActiveCurrency
}

protocol CurrencyStoreObserver: AnyObject {
  func didGetCurrencyStoreEvent(_ event: CurrencyStoreEvent)
}

final class CurrencyStore {
  
  private let currencyService: CurrencyService
  
  init(currencyService: CurrencyService) {
    self.currencyService = currencyService
  }
  
  func getActiveCurrency() -> Currency {
    do {
      return try currencyService.getActiveCurrency()
    } catch {
      return .USD
    }
  }
  
  func setActiveCurrency(_ currency: Currency) {
    do {
      try currencyService.setActiveCurrency(currency)
    } catch {
      print(error)
    }
    notifyObservers(event: .didUpdateActiveCurrency)
  }
  
  private var observers = [CurrencyStoreObserverWrapper]()
  
  struct CurrencyStoreObserverWrapper {
    weak var observer: CurrencyStoreObserver?
  }
  
  func addObserver(_ observer: CurrencyStoreObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(CurrencyStoreObserverWrapper(observer: observer))
  }
  
  func removeObserver(_ observer: CurrencyStoreObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension CurrencyStore {
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }
  
  func notifyObservers(event: CurrencyStoreEvent) {
    observers.forEach { $0.observer?.didGetCurrencyStoreEvent(event) }
  }
}
