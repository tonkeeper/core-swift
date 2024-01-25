import Foundation
import CoreComponents

enum WalletsStoreEvent {
  case didUpdateWallets
  case didUpdateActiveWallet
}

protocol WalletsStoreObserver: AnyObject {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent)
}

final class WalletsStore {
  public private(set) var wallets: [Wallet]
  public private(set) var activeWallet: Wallet
  
  init(wallets: [Wallet],
       activeWallet: Wallet) {
    self.wallets = wallets
    self.activeWallet = activeWallet
  }

  private var observers = [WalletsStoreObserverWrapper]()
  
  struct WalletsStoreObserverWrapper {
    weak var observer: WalletsStoreObserver?
  }
  
  func addObserver(_ observer: WalletsStoreObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(WalletsStoreObserverWrapper(observer: observer))
  }
  
  func removeObserver(_ observer: WalletsStoreObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension WalletsStore {
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }
  
  func notifyObservers(event: WalletsStoreEvent) {
    observers.forEach { $0.observer?.didGetWalletsStoreEvent(event) }
  }
}

extension WalletsStore: WalletsStoreUpdateObserver {
  func didGetWalletsStoreUpdateEvent(_ event: WalletsStoreUpdateEvent) {
    switch event {
    case .didMakeWalletActive(let activeWallet):
      self.activeWallet = activeWallet
      notifyObservers(event: .didUpdateActiveWallet)
    case .didUpdateWallets(let wallets):
      self.wallets = wallets
      notifyObservers(event: .didUpdateWallets)
    }
  }
}

