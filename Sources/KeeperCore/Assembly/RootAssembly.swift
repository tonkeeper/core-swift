import Foundation

final class RootAssembly {
  
  private let servicesAssembly: ServicesAssembly
  private let walletAssembly: WalletAssembly
  
  init(servicesAssembly: ServicesAssembly,
       walletAssembly: WalletAssembly) {
    self.servicesAssembly = servicesAssembly
    self.walletAssembly = walletAssembly
  }
  
  private var _rootController: RootController?
  func rootController() -> RootController {
    if let rootController = _rootController {
      return rootController
    } else {
      let rootController = RootController(keeperInfoService: servicesAssembly.keeperInfoService())
      walletAssembly.walletListUpdater().addObserver(rootController)
      self._rootController = rootController
      return rootController
    }
  }
}
