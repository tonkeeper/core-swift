import Foundation

public final class CollectiblesController {

  private let walletsStore: WalletsStore
  
  init(walletsStore: WalletsStore) {
    self.walletsStore = walletsStore
  }
  
  public var wallet: Wallet {
    walletsStore.activeWallet
  }
}
