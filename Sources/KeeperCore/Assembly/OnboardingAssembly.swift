import Foundation

public final class OnboardingAssembly {
  
  private let servicesAssembly: ServicesAssembly
  private let coreAssembly: CoreAssembly
  private let walletAssembly: WalletAssembly
  
  init(servicesAssembly: ServicesAssembly, 
       coreAssembly: CoreAssembly,
       walletAssembly: WalletAssembly) {
    self.servicesAssembly = servicesAssembly
    self.coreAssembly = coreAssembly
    self.walletAssembly = walletAssembly
  }
  
  func walletListUpdater() -> WalletListUpdater {
    walletAssembly.walletListUpdater()
  }
}

public extension OnboardingAssembly {
  func walletAddController() -> WalletAddController {
    WalletAddController(walletListUpdater: walletListUpdater())
  }
}
