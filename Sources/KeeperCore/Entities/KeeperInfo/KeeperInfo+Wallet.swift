extension KeeperInfo {
  func setWallets(_ wallets: [Wallet]) -> KeeperInfo {
    KeeperInfo(
      wallets: wallets,
      currentWallet: self.currentWallet,
      securitySettings: self.securitySettings,
      assetsPolicy: self.assetsPolicy,
      appCollection: self.appCollection
    )
  }
  
  func setActiveWallet(_ wallet: Wallet) -> KeeperInfo {
    KeeperInfo(
      wallets: self.wallets,
      currentWallet: wallet,
      securitySettings: self.securitySettings,
      assetsPolicy: self.assetsPolicy,
      appCollection: self.appCollection
    )
  }
  
  func setWallets(_ wallets: [Wallet], 
                  activeWallet: Wallet) -> KeeperInfo {
    KeeperInfo(
      wallets: wallets,
      currentWallet: activeWallet,
      securitySettings: self.securitySettings,
      assetsPolicy: self.assetsPolicy,
      appCollection: self.appCollection
    )
  }
}
