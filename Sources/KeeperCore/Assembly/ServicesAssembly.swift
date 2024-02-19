import Foundation

public final class ServicesAssembly {

  private let repositoriesAssembly: RepositoriesAssembly
  private let apiAssembly: APIAssembly
  private let tonkeeperAPIAssembly: TonkeeperAPIAssembly
  
  init(repositoriesAssembly: RepositoriesAssembly,
       apiAssembly: APIAssembly,
       tonkeeperAPIAssembly: TonkeeperAPIAssembly) {
    self.repositoriesAssembly = repositoriesAssembly
    self.apiAssembly = apiAssembly
    self.tonkeeperAPIAssembly = tonkeeperAPIAssembly
  }
  
  func walletsService() -> WalletsService {
    WalletsServiceImplementation(keeperInfoRepository: repositoriesAssembly.keeperInfoRepository())
  }
  
  func balanceService() -> BalanceService {
    BalanceServiceImplementation(
      tonBalanceService: tonBalanceService(),
      jettonsBalanceService: jettonsBalanceService(),
      walletBalanceRepository: repositoriesAssembly.walletBalanceRepository())
  }
  
  func tonBalanceService() -> TonBalanceService {
    TonBalanceServiceImplementation(api: apiAssembly.api)
  }
  
  func jettonsBalanceService() -> JettonBalanceService {
    JettonBalanceServiceImplementation(api: apiAssembly.api)
  }
  
  func activeWalletsService() -> ActiveWalletsService {
    ActiveWalletsServiceImplementation(api: apiAssembly.api,
                                       jettonsBalanceService: jettonsBalanceService())
  }
  
  func ratesService() -> RatesService {
    RatesServiceImplementation(
      api: apiAssembly.api,
      ratesRepository: repositoriesAssembly.ratesRepository()
    )
  }
  
  func currencyService() -> CurrencyService {
    CurrencyServiceImplementation(
      keeperInfoRepository: repositoriesAssembly.keeperInfoRepository()
    )
  }
  
  func historyService() -> HistoryService {
    HistoryServiceImplementation(
      api: apiAssembly.api,
      repository: repositoriesAssembly.historyRepository()
    )
  }
  
  func nftService() -> NFTService {
    NFTServiceImplementation(
      api: apiAssembly.api,
      nftRepository: repositoriesAssembly.nftRepository()
    )
  }
  
  func accountNftService() -> AccountNFTService {
    AccountNFTServiceImplementation(
      api: apiAssembly.api,
      accountNFTRepository: repositoriesAssembly.accountsNftRepository()
    )
  }
  
  func chartService() -> ChartService {
    ChartServiceImplementation(api: tonkeeperAPIAssembly.api)
  }
  
  func securityService() -> SecurityService {
    SecurityServiceImplementation(
      keeperInfoRepository: repositoriesAssembly.keeperInfoRepository()
    )
  }
  
  func setupService() -> SetupService {
    SetupServiceImplementation(
      keeperInfoRepository: repositoriesAssembly.keeperInfoRepository()
    )
  }
}
