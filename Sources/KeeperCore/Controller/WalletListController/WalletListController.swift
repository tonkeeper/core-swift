import Foundation
import CoreComponents

public final class WalletMainController {
  
  public var didUpdateActiveWallet: ((WalletModel) -> Void)?
  
  public struct WalletModel {
    public let name: String
    public let colorIdentifier: String
  }
  
  private let walletListProvider: WalletListProvider
  
  init(walletListProvider: WalletListProvider) {
    self.walletListProvider = walletListProvider
    walletListProvider.addObserver(self)
  }
  
  public func getActiveWallet() {
    let activeWallet = walletListProvider.activeWallet
    let model = WalletModel(name: activeWallet.metaData.emoji + " " + activeWallet.metaData.label,
                            colorIdentifier: activeWallet.metaData.colorIdentifier)
    didUpdateActiveWallet?(model)
  }
}

extension WalletMainController: WalletListProviderObserver {
  func didGetWalletListProviderEvent(_ event: WalletListProviderEvent) {
    switch event {
    case .didChangeActiveWallet:
      getActiveWallet()
    default: break
    }
  }
}
