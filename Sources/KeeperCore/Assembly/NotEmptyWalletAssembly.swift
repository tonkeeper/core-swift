import Foundation

public final class NotEmptyWalletAssembly {
  
  private let servicesAssembly: ServicesAssembly
  private let coreAssembly: CoreAssembly
  private let walletAssembly: WalletAssembly
  
  init(servicesAssembly: ServicesAssembly, 
       coreAssembly: CoreAssembly,
       walletAssembly: WalletAssembly,
       wallets: [Wallet],
       activeWallet: Wallet) {
    self.servicesAssembly = servicesAssembly
    self.coreAssembly = coreAssembly
    self.walletAssembly = walletAssembly
    
    self.walletListProvider = WalletListProvider(
      wallets: wallets,
      activeWallet: activeWallet
    )
  }
  
  private let walletListProvider: WalletListProvider
  
  func walletMainController() -> WalletMainController {
    WalletMainController(walletListProvider: walletListProvider)
  }
}
