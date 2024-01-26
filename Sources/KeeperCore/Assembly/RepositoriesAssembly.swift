import Foundation

public final class RepositoriesAssembly {
  
  private let coreAssembly: CoreAssembly
  
  init(coreAssembly: CoreAssembly) {
    self.coreAssembly = coreAssembly
  }
  
  func mnemonicRepository() -> WalletMnemonicRepository {
    coreAssembly.mnemonicVault()
  }
  
  func keeperInfoRepository() -> KeeperInfoRepository {
    coreAssembly.sharedFileSystemVault()
  }
  
  func walletBalanceRepository() -> WalletBalanceRepository {
    WalletBalanceRepositoryimplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
}
