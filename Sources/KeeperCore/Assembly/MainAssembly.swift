import Foundation

public final class MainAssembly {
  
  public struct Dependencies {
    let wallets: [Wallet]
    let activeWallet: Wallet
    
    public init(wallets: [Wallet], activeWallet: Wallet) {
      self.wallets = wallets
      self.activeWallet = activeWallet
    }
  }
  
  let walletAssembly: WalletAssembly
  let notEmptyWalletAssembly: NotEmptyWalletAssembly
  let servicesAssembly: ServicesAssembly
  let coreAssembly: CoreAssembly
  
  init(walletAssembly: WalletAssembly,
       notEmptyWalletAssembly: NotEmptyWalletAssembly,
       servicesAssembly: ServicesAssembly,
       coreAssembly: CoreAssembly) {
    self.walletAssembly = walletAssembly
    self.notEmptyWalletAssembly = notEmptyWalletAssembly
    self.servicesAssembly = servicesAssembly
    self.coreAssembly = coreAssembly
  }
  
  public func walletMainController() -> WalletMainController {
    notEmptyWalletAssembly.walletMainController()
  }
}
