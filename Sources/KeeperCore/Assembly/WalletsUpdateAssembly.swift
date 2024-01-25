import Foundation

public final class WalletsUpdateAssembly {
  
  private let servicesAssembly: ServicesAssembly
  private let repositoriesAssembly: RepositoriesAssembly
  
  init(servicesAssembly: ServicesAssembly,
       repositoriesAssembly: RepositoriesAssembly) {
    self.servicesAssembly = servicesAssembly
    self.repositoriesAssembly = repositoriesAssembly
  }
  
  lazy var walletsStoreUpdate: WalletsStoreUpdate = {
    WalletsStoreUpdate(walletsService: servicesAssembly.walletsService())
  }()
  
  public func walletAddController() -> WalletAddController {
    WalletAddController(
      walletsStoreUpdate: walletsStoreUpdate,
      mnemonicRepositoty: repositoriesAssembly.mnemonicRepository()
    )
  }
}
