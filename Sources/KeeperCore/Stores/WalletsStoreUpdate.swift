import Foundation
import CoreComponents

enum WalletsStoreUpdateEvent {
  case didMakeWalletActive(Wallet)
  case didUpdateWallets([Wallet])
}

protocol WalletsStoreUpdateObserver: AnyObject {
  func didGetWalletsStoreUpdateEvent(_ event: WalletsStoreUpdateEvent)
}

final class WalletsStoreUpdate {
  private let walletsService: WalletsService
  
  init(walletsService: WalletsService) {
    self.walletsService = walletsService
  }
  
  func addWallets(_ wallets: [Wallet]) throws {
    try walletsService.addWallets(wallets)
    notifyObserversDidUpdateWallets()
  }

  func makeWalletActive(_ wallet: Wallet) throws {
    try walletsService.setWalletActive(wallet)
    notifyObserversDidUpdateActiveWallet()
  }

  func moveWallet(fromIndex: Int, toIndex: Int) throws {
    try walletsService.moveWallet(fromIndex: fromIndex, toIndex: toIndex)
    notifyObserversDidUpdateWallets()
  }

  private var observers = [WalletsStoreUpdateObserverWrapper]()
  
  struct WalletsStoreUpdateObserverWrapper {
    weak var observer: WalletsStoreUpdateObserver?
  }
  
  func addObserver(_ observer: WalletsStoreUpdateObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(WalletsStoreUpdateObserverWrapper(observer: observer))
  }
  
  func removeObserver(_ observer: WalletsStoreObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension WalletsStoreUpdate {
  func notifyObserversDidUpdateWallets() {
    guard let wallets = try? walletsService.getWallets() else { return }
    notifyObservers(event: .didUpdateWallets(wallets))
  }
  
  func notifyObserversDidUpdateActiveWallet() {
    guard let activeWallet = try? walletsService.getActiveWallet() else { return }
    notifyObservers(event: .didMakeWalletActive(activeWallet))
  }
  
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }
  
  func notifyObservers(event: WalletsStoreUpdateEvent) {
    observers.forEach { $0.observer?.didGetWalletsStoreUpdateEvent(event) }
  }
}

