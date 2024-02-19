import Foundation

enum SecurityStoreEvent {
  case didUpdateSecuritySettings
}

protocol SecurityStoreObserver: AnyObject {
  func didGetSecurityStoreEvent(_ event: SecurityStoreEvent)
}

final class SecurityStore {
  
  private let securityService: SecurityService
  
  init(securityService: SecurityService) {
    self.securityService = securityService
  }
  
  var isBiometryEnabled: Bool {
    securityService.isBiometryTurnedOn
  }
  
  func setIsBiometryEnabled(_ isBiometryEnabled: Bool) throws {
    try securityService.updateBiometry(isBiometryEnabled)
    notifyObservers(event: .didUpdateSecuritySettings)
  }
  
  private var observers = [SecurityStoreObserverWrapper]()
  
  struct SecurityStoreObserverWrapper {
    weak var observer: SecurityStoreObserver?
  }
  
  func addObserver(_ observer: SecurityStoreObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(SecurityStoreObserverWrapper(observer: observer))
  }
  
  func removeObserver(_ observer: CurrencyStoreObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension SecurityStore {
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }
  
  func notifyObservers(event: SecurityStoreEvent) {
    observers.forEach { $0.observer?.didGetSecurityStoreEvent(event) }
  }
}
