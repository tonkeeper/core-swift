import Foundation

public final class ServicesAssembly {

  private let repositoriesAssembly: RepositoriesAssembly
  private let apiAssembly: APIAssembly
  
  init(repositoriesAssembly: RepositoriesAssembly,
       apiAssembly: APIAssembly) {
    self.repositoriesAssembly = repositoriesAssembly
    self.apiAssembly = apiAssembly
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
}
