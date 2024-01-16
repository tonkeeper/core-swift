import Foundation

public final class Assembly {
  public struct Dependencies {
    public let cacheURL: URL
    public let sharedCacheURL: URL
    
    public init(cacheURL: URL,
                sharedCacheURL: URL) {
      self.cacheURL = cacheURL
      self.sharedCacheURL = sharedCacheURL
    }
  }
  
  private let coreAssembly: CoreAssembly
  private lazy var servicesAssembly = ServicesAssembly(coreAssembly: coreAssembly)
  private lazy var walletAssembly = WalletAssembly(
    servicesAssembly: servicesAssembly,
    coreAssembly: coreAssembly
  )
  private lazy var rootAssembly = RootAssembly(
    servicesAssembly: servicesAssembly,
    walletAssembly: walletAssembly
  )
  
  private let dependencies: Dependencies
  
  public init(dependencies: Dependencies) {
    self.dependencies = dependencies
    self.coreAssembly = CoreAssembly(
      cacheURL: dependencies.cacheURL,
      sharedCacheURL: dependencies.sharedCacheURL
    )
  }
}

public extension Assembly {
  func rootController() -> RootController {
    rootAssembly.rootController()
  }
  
  func onboardingAssembly() -> OnboardingAssembly {
    OnboardingAssembly(
      servicesAssembly: servicesAssembly,
      coreAssembly: coreAssembly,
      walletAssembly: walletAssembly
    )
  }
  
  func mainAssembly(dependencies: MainAssembly.Dependencies) -> MainAssembly {
    let notEmptyWalletAssembly = NotEmptyWalletAssembly(
      servicesAssembly: servicesAssembly,
      coreAssembly: coreAssembly,
      walletAssembly: walletAssembly,
      wallets: dependencies.wallets,
      activeWallet: dependencies.activeWallet)
    
    return MainAssembly(
      walletAssembly: walletAssembly,
      notEmptyWalletAssembly: notEmptyWalletAssembly,
      servicesAssembly: servicesAssembly,
      coreAssembly: coreAssembly)
  }
}
