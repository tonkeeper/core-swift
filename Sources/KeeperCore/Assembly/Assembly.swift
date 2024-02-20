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
  private lazy var repositoriesAssembly = RepositoriesAssembly(coreAssembly: coreAssembly)
  private lazy var configurationAssembly = ConfigurationAssembly(
    tonkeeperApiAssembly: tonkeeperApiAssembly,
    coreAssembly: coreAssembly
  )
  private lazy var apiAssembly = APIAssembly(configurationAssembly: configurationAssembly)
  private lazy var tonkeeperApiAssembly = TonkeeperAPIAssembly()
  private lazy var servicesAssembly = ServicesAssembly(
    repositoriesAssembly: repositoriesAssembly, 
    apiAssembly: apiAssembly,
    tonkeeperAPIAssembly: tonkeeperApiAssembly
  )
  private lazy var storesAssembly = StoresAssembly(
    servicesAssembly: servicesAssembly,
    apiAssembly: apiAssembly
  )
  private lazy var formattersAssembly = FormattersAssembly()
  private var walletUpdateAssembly: WalletsUpdateAssembly {
    WalletsUpdateAssembly(
      servicesAssembly: servicesAssembly,
      repositoriesAssembly: repositoriesAssembly
    )
  }
  private lazy var passcodeAssembly = PasscodeAssembly(
    repositoriesAssembly: repositoriesAssembly,
    storesAssembly: storesAssembly
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
  func rootAssembly() -> RootAssembly {
    RootAssembly(repositoriesAssembly: repositoriesAssembly,
                 coreAssembly: coreAssembly,
                 servicesAssembly: servicesAssembly,
                 storesAssembly: storesAssembly,
                 formattersAssembly: formattersAssembly,
                 walletsUpdateAssembly: walletUpdateAssembly,
                 configurationAssembly: configurationAssembly,
                 passcodeAssembly: passcodeAssembly)
  }
}
