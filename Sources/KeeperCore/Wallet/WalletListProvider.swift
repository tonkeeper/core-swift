import Foundation
import CoreComponents

enum WalletListProviderEvent {
  case didAddWallet
}

enum WalletListProviderError: Swift.Error {
  case noWalletAdded
}

protocol WalletListProviderObserver: AnyObject {
  func didGetWalletListProviderEvent(_ event: WalletListProviderEvent)
}

final class WalletListProvider {
  public var wallets: [Wallet] {
    get throws {
      try keeperInfoService.getKeeperInfo().wallets
    }
  }
  
  public var activeWallet: Wallet {
    get throws {
      guard let keeperInfo = try? keeperInfoService.getKeeperInfo(),
            !keeperInfo.wallets.isEmpty else {
        throw WalletListProviderError.noWalletAdded
      }
      return keeperInfo.wallets.first(where: { $0.identity == keeperInfo.currentWallet }) ?? keeperInfo.wallets[0]
    }
  }
  
  private let keeperInfoService: KeeperInfoService
  
  init(keeperInfoService: KeeperInfoService) {
    self.keeperInfoService = keeperInfoService
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
