import Foundation
import CoreComponents

enum WalletListProviderEvent {
  case didAddWallet
  case didChangeActiveWallet(wallet: Wallet)
}

enum WalletListProviderError: Swift.Error {
  case noWalletAdded
}

protocol WalletListProviderObserver: AnyObject {
  func didGetWalletListProviderEvent(_ event: WalletListProviderEvent)
}

final class WalletListProvider {
  public private(set) var wallets: [Wallet]
  public private(set) var activeWallet: Wallet
  
  init(wallets: [Wallet], activeWallet: Wallet) {
    self.wallets = wallets
    self.activeWallet = activeWallet
  }
  
  private var observers = [WalletListProviderWrapper]()
  
  struct WalletListProviderWrapper {
    weak var observer: WalletListProviderObserver?
  }
  
  func addObserver(_ observer: WalletListProviderObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(WalletListProviderWrapper(observer: observer))
  }
  
  func removeObserver(_ observer: WalletListProviderObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension WalletListProvider {
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }
  
  func notifyObservers(event: WalletListProviderEvent) {
    observers.forEach { $0.observer?.didGetWalletListProviderEvent(event) }
  }
}

extension WalletListProvider: WalletListUpdaterObserver {
  func didGetWalletListUpdaterEvent(_ event: WalletListUpdaterEvent) {
    switch event {
    case .didAddWallet: notifyObservers(event: .didAddWallet)
    }
  }
}
