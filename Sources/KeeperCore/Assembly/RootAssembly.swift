import Foundation

final class RootAssembly {
  
  private let walletAssembly: WalletAssembly
  
  init(walletAssembly: WalletAssembly) {
    self.walletAssembly = walletAssembly
  }
  
  private var _rootController: RootController?
  func rootController() -> RootController {
    if let rootController = _rootController {
      return rootController
    } else {
      let rootController = RootController(walletListProvider: walletAssembly.walletListProvider())
      self._rootController = rootController
      return rootController
    }
  }
}
