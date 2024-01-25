import Foundation

public final class RootAssembly {
  private let servicesAssembly: ServicesAssembly
  private let coreAssembly: CoreAssembly
  private let walletsUpdateAssembly: WalletsUpdateAssembly

  init(coreAssembly: CoreAssembly,
       servicesAssembly: ServicesAssembly,
       walletsUpdateAssembly: WalletsUpdateAssembly) {
    self.coreAssembly = coreAssembly
    self.servicesAssembly = servicesAssembly
    self.walletsUpdateAssembly = walletsUpdateAssembly
  }
  
  private var _rootController: RootController?
  public func rootController() -> RootController {
    if let rootController = _rootController {
      return rootController
    } else {
      let rootController = RootController(walletsService: servicesAssembly.walletsService())
      self._rootController = rootController
      return rootController
    }
  }
  
  public func onboardingAssembly() -> OnboardingAssembly {
    OnboardingAssembly(walletsUpdateAssembly: walletsUpdateAssembly)
  }
  
  public func mainAssembly(dependencies: MainAssembly.Dependencies) -> MainAssembly {
    let walletAssembly = WalletAssembly(
      servicesAssembly: servicesAssembly,
      walletUpdateAssembly: walletsUpdateAssembly,
      wallets: dependencies.wallets,
      activeWallet: dependencies.activeWallet)
    return MainAssembly(
      walletAssembly: walletAssembly,
      walletUpdateAssembly: walletsUpdateAssembly,
      servicesAssembly: servicesAssembly)
  }
}
