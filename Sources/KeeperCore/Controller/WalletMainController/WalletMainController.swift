import Foundation
import CoreComponents

public final class WalletMainController {
  
  public var didUpdateActiveWallet: ((WalletModel) -> Void)?
  
  public struct WalletModel {
    public let name: String
    public let colorIdentifier: String
  }
  
  private let walletsStore: WalletsStore
  
  init(walletsStore: WalletsStore) {
    self.walletsStore = walletsStore
    self.walletsStore.addObserver(self)
  }
  
  public func getActiveWallet() {
    let activeWallet = walletsStore.activeWallet
    let model = WalletModel(name: activeWallet.metaData.emoji + " " + activeWallet.metaData.label,
                            colorIdentifier: activeWallet.metaData.colorIdentifier)
    didUpdateActiveWallet?(model)
  }
}

extension WalletMainController: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    switch event {
    case .didUpdateActiveWallet:
      getActiveWallet()
    default: break
    }
  }
}
