import Foundation
import TonSwift

public final class MainAssembly {
  
  public struct Dependencies {
    let wallets: [Wallet]
    let activeWallet: Wallet
    
    public init(wallets: [Wallet], activeWallet: Wallet) {
      self.wallets = wallets
      self.activeWallet = activeWallet
    }
  }
  
  let repositoriesAssembly: RepositoriesAssembly
  let walletAssembly: WalletAssembly
  public let walletUpdateAssembly: WalletsUpdateAssembly
  let servicesAssembly: ServicesAssembly
  let storesAssembly: StoresAssembly
  let formattersAssembly: FormattersAssembly
  let configurationAssembly: ConfigurationAssembly
  public let passcodeAssembly: PasscodeAssembly
  
  init(repositoriesAssembly: RepositoriesAssembly,
       walletAssembly: WalletAssembly,
       walletUpdateAssembly: WalletsUpdateAssembly,
       servicesAssembly: ServicesAssembly,
       storesAssembly: StoresAssembly,
       formattersAssembly: FormattersAssembly,
       configurationAssembly: ConfigurationAssembly,
       passcodeAssembly: PasscodeAssembly) {
    self.repositoriesAssembly = repositoriesAssembly
    self.walletAssembly = walletAssembly
    self.walletUpdateAssembly = walletUpdateAssembly
    self.servicesAssembly = servicesAssembly
    self.storesAssembly = storesAssembly
    self.formattersAssembly = formattersAssembly
    self.configurationAssembly = configurationAssembly
    self.passcodeAssembly = passcodeAssembly
  }
  
  public func mainController() -> MainController {
    MainController(
      walletsStore: walletAssembly.walletStore,
      nftsStoreProvider: {
        [storesAssembly] wallet in storesAssembly.nftsStore(wallet: wallet)
      },
      backgroundUpdateStore: storesAssembly.backgroundUpdateStore,
      tonConnectService: servicesAssembly.tonConnectService()
    )
  }
  
  public func walletMainController() -> WalletMainController {
    WalletMainController(
      walletsStore: walletAssembly.walletStore,
      balanceStore: storesAssembly.balanceStore,
      ratesStore: storesAssembly.ratesStore,
      backgroundUpdateStore: storesAssembly.backgroundUpdateStore
    )
  }
  
  public func walletListController() -> WalletListController {
    WalletListController(
      walletsStore: walletAssembly.walletStore,
      walletsStoreUpdate: walletUpdateAssembly.walletsStoreUpdate,
      balanceStore: storesAssembly.balanceStore,
      ratesStore: storesAssembly.ratesStore,
      currencyStore: storesAssembly.currencyStore,
      walletListMapper: walletListMapper
    )
  }
  
  public func walletBalanceController(wallet: Wallet) -> WalletBalanceController {
    WalletBalanceController(
      wallet: wallet,
      walletsStore: walletAssembly.walletStore,
      balanceStore: storesAssembly.balanceStore,
      ratesStore: storesAssembly.ratesStore,
      currencyStore: storesAssembly.currencyStore,
      securityStore: storesAssembly.securityStore,
      setupStore: storesAssembly.setupStore,
      backgroundUpdateStore: storesAssembly.backgroundUpdateStore,
      walletBalanceMapper: walletBalanceMapper
    )
  }
  
  public var settingsController: SettingsController {
    SettingsController(
      walletsStore: walletAssembly.walletStore,
      currencyStore: storesAssembly.currencyStore,
      configurationStore: configurationAssembly.remoteConfigurationStore
    )
  }
  
  public func historyController() -> HistoryController {
    HistoryController(walletsStore: walletAssembly.walletStore,
                      backgroundUpdateStore: storesAssembly.backgroundUpdateStore)
  }
  
  public func historyListController() -> HistoryListController {
    HistoryListController(
      paginatorProvider: { [servicesAssembly]
        address, didSendEvent in
        let loader = HistoryListAllEventsLoader(
          historyService: servicesAssembly.historyService()
        )
        return HistoryListPaginator(loader: loader, address: address, didSendEvent: didSendEvent)
      },
      walletsStore: walletAssembly.walletStore,
      nftService: servicesAssembly.nftService(),
      historyListMapper: historyListMapper,
      dateFormatter: formattersAssembly.dateFormatter
    )
  }
  
  public func tonEventsHistoryListController() -> HistoryListController {
    HistoryListController(
      paginatorProvider: { [servicesAssembly]
        address, didSendEvent in
        let loader = HistoryListTonEventsLoader(
          historyService: servicesAssembly.historyService()
        )
        return HistoryListPaginator(loader: loader, address: address, didSendEvent: didSendEvent)
      },
      walletsStore: walletAssembly.walletStore,
      nftService: servicesAssembly.nftService(),
      historyListMapper: historyListMapper,
      dateFormatter: formattersAssembly.dateFormatter
    )
  }
  
  public func jettonEventsHistoryListController(jettonInfo: JettonInfo) -> HistoryListController {
    HistoryListController(
      paginatorProvider: { [servicesAssembly]
        address, didSendEvent in
        let loader = HistoryListJettonEventsLoader(jettonInfo: jettonInfo,
          historyService: servicesAssembly.historyService()
        )
        return HistoryListPaginator(loader: loader, address: address, didSendEvent: didSendEvent)
      },
      walletsStore: walletAssembly.walletStore,
      nftService: servicesAssembly.nftService(),
      historyListMapper: historyListMapper,
      dateFormatter: formattersAssembly.dateFormatter
    )
  }
  
  public func tonTokenDetailsController() -> TokenDetailsController {
    let configurator = TonTokenDetailsControllerConfigurator(
      mapper: tokenDetailsMapper
    )
    return TokenDetailsController(
      configurator: configurator,
      walletsStore: walletAssembly.walletStore,
      balanceStore: storesAssembly.balanceStore,
      ratesStore: storesAssembly.ratesStore,
      currencyStore: storesAssembly.currencyStore
    )
  }
  
  public func jettonTokenDetailsController(jettonInfo: JettonInfo) -> TokenDetailsController {
    let configurator = JettonTokenDetailsControllerConfigurator(
      jettonInfo: jettonInfo,
      mapper: tokenDetailsMapper
    )
    return TokenDetailsController(
      configurator: configurator,
      walletsStore: walletAssembly.walletStore,
      balanceStore: storesAssembly.balanceStore,
      ratesStore: storesAssembly.ratesStore,
      currencyStore: storesAssembly.currencyStore
    )
  }
  
  public func chartController() -> ChartController {
    ChartController(
      chartService: servicesAssembly.chartService(),
      ratesStore: storesAssembly.ratesStore,
      currencyStore: storesAssembly.currencyStore,
      decimalAmountFormatter: formattersAssembly.decimalAmountFormatter
    )
  }
  
  public func receiveController(token: Token) -> ReceiveController {
    ReceiveController(
      token: token,
      walletsStore: walletAssembly.walletStore,
      deeplinkGenerator: DeeplinkGenerator()
    )
  }
  
  public func historyEventDetailsController(event: AccountEventDetailsEvent) -> HistoryEventDetailsController {
    HistoryEventDetailsController(
      event: event,
      amountMapper: AmountHistoryListEventAmountMapper(amountFormatter: formattersAssembly.amountFormatter),
      ratesStore: storesAssembly.ratesStore,
      walletsStore: walletAssembly.walletStore,
      currencyStore: storesAssembly.currencyStore,
      nftService: servicesAssembly.nftService()
    )
  }
  
  public func collectiblesController() -> CollectiblesController {
    CollectiblesController(
      walletsStore: walletAssembly.walletStore,
      backgroundUpdateStore: storesAssembly.backgroundUpdateStore
    )
  }
  
  public func collectiblesListController(wallet: Wallet) -> CollectiblesListController {
    CollectiblesListController(nftsStore: storesAssembly.nftsStore(wallet: wallet))
  }
  
  public func recoveryPhraseController(wallet: Wallet) -> RecoveryPhraseController {
    RecoveryPhraseController(
      wallet: wallet,
      mnemonicRepository: repositoriesAssembly.mnemonicRepository()
    )
  }
  
  public func backupController(wallet: Wallet) -> BackupController {
    BackupController(
      wallet: wallet,
      backupStore: storesAssembly.backupStore,
      walletsStore: walletAssembly.walletStore,
      dateFormatter: formattersAssembly.dateFormatter
    )
  }
  
  public func settingsSecurityController() -> SettingsSecurityController {
    SettingsSecurityController(
      securityStore: storesAssembly.securityStore
    )
  }
  
  public func scannerController() -> ScannerController {
    ScannerController(
      deeplinkParser: DefaultDeeplinkParser(
        parsers: [TonDeeplinkParser(),
                 TonConnectDeeplinkParser()]
      )
    )
  }
  
  public func tonConnectConnectController(parameters: TonConnectParameters,
                                          manifest: TonConnectManifest) -> TonConnectConnectController {
    TonConnectConnectController(
      parameters: parameters,
      manifest: manifest,
      walletsStore: walletAssembly.walletStore,
      tonConnectAppsStore: storesAssembly.tonConnectAppsStore
    )
  }
}

private extension MainAssembly {
  var walletBalanceMapper: WalletBalanceMapper {
    WalletBalanceMapper(
      amountFormatter: formattersAssembly.amountFormatter,
      decimalAmountFormatter: formattersAssembly.decimalAmountFormatter,
      rateConverter: RateConverter())
  }
  
  var walletListMapper: WalletListMapper {
    WalletListMapper(
      amountFormatter: formattersAssembly.amountFormatter,
      decimalAmountFormatter: formattersAssembly.decimalAmountFormatter,
      rateConverter: RateConverter()
    )
  }
  
  var historyListMapper: HistoryListMapper {
    HistoryListMapper(
      dateFormatter: formattersAssembly.dateFormatter,
      amountFormatter: formattersAssembly.amountFormatter,
      amountMapper: SignedAmountHistoryListEventAmountMapper(
        amountAccountHistoryListEventAmountMapper: AmountHistoryListEventAmountMapper(
          amountFormatter: formattersAssembly.amountFormatter
        )
      )
    )
  }
  
  var tokenDetailsMapper: TokenDetailsMapper {
    TokenDetailsMapper(
      amountFormatter: formattersAssembly.amountFormatter,
      rateConverter: RateConverter()
    )
  }
}
