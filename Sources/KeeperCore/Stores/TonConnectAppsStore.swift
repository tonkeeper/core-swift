import Foundation
import TonSwift

enum TonConnectAppsStoreEvent {
  case didUpdateApps
}

protocol TonConnectAppsStoreObserver: AnyObject {
  func didGetTonConnectAppsStoreEvent(_ event: TonConnectAppsStoreEvent)
}

final class TonConnectAppsStore {
  
  private let tonConnectService: TonConnectService
  
  init(tonConnectService: TonConnectService) {
    self.tonConnectService = tonConnectService
  }
  
  func connect(wallet: Wallet,
               parameters: TonConnectParameters,
               manifest: TonConnectManifest) async throws {
    try await tonConnectService.connect(
      wallet: wallet,
      parameters: parameters,
      manifest: manifest
    )
    await MainActor.run {
      notifyObservers(event:.didUpdateApps)
    }
  }
  private var observers = [TonConnectAppsStoreObserverWrapper]()
  
  struct TonConnectAppsStoreObserverWrapper {
    weak var observer: TonConnectAppsStoreObserver?
  }
  
  func addObserver(_ observer: TonConnectAppsStoreObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(TonConnectAppsStoreObserverWrapper(observer: observer))
  }
  
  func removeObserver(_ observer: CurrencyStoreObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension TonConnectAppsStore {
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }
  
  func notifyObservers(event: TonConnectAppsStoreEvent) {
    observers.forEach { $0.observer?.didGetTonConnectAppsStoreEvent(event) }
  }
}
