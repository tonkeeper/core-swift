import Foundation

enum SetupStoreEvent {
  case didUpdateSetupIsFinished
}

protocol SetupStoreObserver: AnyObject {
  func didGetSetupStoreEvent(_ event: SetupStoreEvent)
}

final class SetupStore {
  
  private let setupService: SetupService
  
  init(setupService: SetupService) {
    self.setupService = setupService
  }
  
  var isSetupFinished: Bool {
    setupService.isSetupFinished
  }
  
  func setSetupIsFinished() throws {
    try setupService.setSetupFinished()
    notifyObservers(event: .didUpdateSetupIsFinished)
  }
  
  private var observers = [SetupStoreObserverWrapper]()
  
  struct SetupStoreObserverWrapper {
    weak var observer: SetupStoreObserver?
  }
  
  func addObserver(_ observer: SetupStoreObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(SetupStoreObserverWrapper(observer: observer))
  }
  
  func removeObserver(_ observer: CurrencyStoreObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension SetupStore {
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }
  
  func notifyObservers(event: SetupStoreEvent) {
    observers.forEach { $0.observer?.didGetSetupStoreEvent(event) }
  }
}
