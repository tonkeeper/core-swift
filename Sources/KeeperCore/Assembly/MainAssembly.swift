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
  
  let walletAssembly: WalletAssembly
  public let walletUpdateAssembly: WalletsUpdateAssembly
  let servicesAssembly: ServicesAssembly
  let storesAssembly: StoresAssembly
  let formattersAssembly: FormattersAssembly
  let configurationAssembly: ConfigurationAssembly
  
  init(walletAssembly: WalletAssembly,
       walletUpdateAssembly: WalletsUpdateAssembly,
       servicesAssembly: ServicesAssembly,
       storesAssembly: StoresAssembly,
       formattersAssembly: FormattersAssembly,
       configurationAssembly: ConfigurationAssembly) {
    self.walletAssembly = walletAssembly
    self.walletUpdateAssembly = walletUpdateAssembly
    self.servicesAssembly = servicesAssembly
    self.storesAssembly = storesAssembly
    self.formattersAssembly = formattersAssembly
    self.configurationAssembly = configurationAssembly
  }
  
  public func walletMainController() -> WalletMainController {
    WalletMainController(
      walletsStore: walletAssembly.walletStore,
      balanceStore: storesAssembly.balanceStore,
      ratesStore: storesAssembly.ratesStore
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
      balanceStore: storesAssembly.balanceStore,
      ratesStore: storesAssembly.ratesStore,
      currencyStore: storesAssembly.currencyStore,
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
    HistoryController(walletsStore: walletAssembly.walletStore)
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
      walletsStore: walletAssembly.walletStore
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
