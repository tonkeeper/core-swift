import Foundation

public final class HistoryController {
  
  public var didUpdateWallet: (() -> Void)?
  
  private let walletsStore: WalletsStore
  
  init(walletsStore: WalletsStore) {
    self.walletsStore = walletsStore
    walletsStore.addObserver(self)
  }
  
  public var wallet: Wallet {
    walletsStore.activeWallet
  }
}

extension HistoryController: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    switch event {
    case .didUpdateActiveWallet:
      didUpdateWallet?()
    default:
      break
    }
  }
}
