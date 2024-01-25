import Foundation

public final class WalletAssembly {
  
  private let servicesAssembly: ServicesAssembly
  private let walletUpdateAssembly: WalletsUpdateAssembly
  
  let walletStore: WalletsStore
  
  init(servicesAssembly: ServicesAssembly,
       walletUpdateAssembly: WalletsUpdateAssembly,
       wallets: [Wallet],
       activeWallet: Wallet) {
    self.servicesAssembly = servicesAssembly
    self.walletUpdateAssembly = walletUpdateAssembly
    
    self.walletStore = WalletsStore(
      wallets: wallets,
      activeWallet: activeWallet
    )
    walletUpdateAssembly.walletsStoreUpdate.addObserver(walletStore)
  }
}
