import Foundation

public final class RootAssembly {
  private let servicesAssembly: ServicesAssembly
  private let storesAssembly: StoresAssembly
  private let coreAssembly: CoreAssembly
  private let formattersAssembly: FormattersAssembly
  private let walletsUpdateAssembly: WalletsUpdateAssembly
  private let configurationAssembly: ConfigurationAssembly

  init(coreAssembly: CoreAssembly,
       servicesAssembly: ServicesAssembly,
       storesAssembly: StoresAssembly,
       formattersAssembly: FormattersAssembly,
       walletsUpdateAssembly: WalletsUpdateAssembly,
       configurationAssembly: ConfigurationAssembly) {
    self.coreAssembly = coreAssembly
    self.servicesAssembly = servicesAssembly
    self.storesAssembly = storesAssembly
    self.formattersAssembly = formattersAssembly
    self.walletsUpdateAssembly = walletsUpdateAssembly
    self.configurationAssembly = configurationAssembly
  }
  
  private var _rootController: RootController?
  public func rootController() -> RootController {
    if let rootController = _rootController {
      return rootController
    } else {
      let rootController = RootController(
        walletsService: servicesAssembly.walletsService(),
        remoteConfigurationStore: configurationAssembly.remoteConfigurationStore
      )
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
      servicesAssembly: servicesAssembly,
      storesAssembly: storesAssembly,
      formattersAssembly: formattersAssembly,
      configurationAssembly: configurationAssembly
    )
  }
}
