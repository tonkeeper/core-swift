import Foundation
import CoreComponents

enum WalletsStoreUpdateEvent {
  case didMakeWalletActive(walletId: WalletIdentity)
  case didUpdateWallets
  case didUpdateWallet(walletId: WalletIdentity)
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
    notifyObservers(event: .didUpdateWallets)
  }

  func makeWalletActive(_ wallet: Wallet) throws {
    try walletsService.setWalletActive(wallet)
    notifyObservers(event: .didMakeWalletActive(walletId: wallet.identity))
  }

  func moveWallet(fromIndex: Int, toIndex: Int) throws {
    try walletsService.moveWallet(fromIndex: fromIndex, toIndex: toIndex)
    notifyObservers(event: .didUpdateWallets)
  }
  
  func updateWallet(_ wallet: Wallet, metaData: WalletMetaData) throws {
    try walletsService.updateWallet(wallet: wallet, metaData: metaData)
    notifyObservers(event: .didUpdateWallet(walletId: wallet.identity))
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
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }
  
  func notifyObservers(event: WalletsStoreUpdateEvent) {
    observers.forEach { $0.observer?.didGetWalletsStoreUpdateEvent(event) }
  }
}

