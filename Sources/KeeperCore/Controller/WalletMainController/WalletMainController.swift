import Foundation
import CoreComponents

public final class WalletMainController {
  
  public var didUpdateActiveWallet: (() -> Void)?
  
  public struct WalletModel {
    public let name: String
    public let colorIdentifier: String
  }
  
  private let walletsStore: WalletsStore
  
  init(walletsStore: WalletsStore) {
    self.walletsStore = walletsStore
    self.walletsStore.addObserver(self)
  }
  
  public func getActiveWalletModel() -> WalletModel {
    let activeWallet = walletsStore.activeWallet
    let model = WalletModel(name: activeWallet.metaData.emoji + " " + activeWallet.metaData.label,
                            colorIdentifier: activeWallet.metaData.colorIdentifier)
    return model
  }
  
  public func getActiveWallet() -> Wallet {
    walletsStore.activeWallet
  }
}

extension WalletMainController: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    switch event {
    case .didUpdateActiveWallet:
      didUpdateActiveWallet?()
    default: break
    }
  }
}
