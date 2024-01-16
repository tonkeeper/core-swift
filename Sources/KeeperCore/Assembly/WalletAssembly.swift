import Foundation

public final class WalletAssembly {
  
  private let servicesAssembly: ServicesAssembly
  private let coreAssembly: CoreAssembly
  
  init(servicesAssembly: ServicesAssembly, coreAssembly: CoreAssembly) {
    self.servicesAssembly = servicesAssembly
    self.coreAssembly = coreAssembly
  }
  
  private var _walletListUpdater: WalletListUpdater?
  func walletListUpdater() -> WalletListUpdater {
    if let walletListUpdater = _walletListUpdater {
      return walletListUpdater
    } else {
      let walletListUpdater = WalletListUpdater(
        keeperInfoService: servicesAssembly.keeperInfoService(),
        mnemonicRepository: coreAssembly.mnemonicRepository()
      )
      _walletListUpdater = walletListUpdater
      return walletListUpdater
    }
  }

  func walletAddController() -> WalletAddController {
    WalletAddController(walletListUpdater: walletListUpdater())
  }
}
