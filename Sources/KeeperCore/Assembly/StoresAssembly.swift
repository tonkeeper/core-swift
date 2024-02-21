import Foundation
import TonSwift

public final class StoresAssembly {
  
  private let servicesAssembly: ServicesAssembly
  private let apiAssembly: APIAssembly
  private let coreAssembly: CoreAssembly
  
  init(servicesAssembly: ServicesAssembly,
       apiAssembly: APIAssembly, 
       coreAssembly: CoreAssembly) {
    self.servicesAssembly = servicesAssembly
    self.apiAssembly = apiAssembly
    self.coreAssembly = coreAssembly
  }
  
  private weak var _balanceStore: BalanceStore?
  var balanceStore: BalanceStore {
    if let balanceStore = _balanceStore {
      return balanceStore
    } else {
      let balanceStore = BalanceStore(balanceService: servicesAssembly.balanceService())
      _balanceStore = balanceStore
      return balanceStore
    }
  }
  
  private weak var _ratesStore: RatesStore?
  var ratesStore: RatesStore {
    if let ratesStore = _ratesStore {
      return ratesStore
    } else {
      let ratesStore = RatesStore(ratesService: servicesAssembly.ratesService())
      _ratesStore = ratesStore
      return ratesStore
    }
  }
  
  private weak var _currencyStore: CurrencyStore?
  var currencyStore: CurrencyStore {
    if let currencyStore = _currencyStore {
      return currencyStore
    } else {
      let currencyStore = CurrencyStore(currencyService: servicesAssembly.currencyService())
      _currencyStore = currencyStore
      return currencyStore
    }
  }
  
  private weak var _backupStore: BackupStore?
  var backupStore: BackupStore {
    if let backupStore = _backupStore {
      return backupStore
    } else {
      let backupStore = BackupStore(
        walletService: servicesAssembly.walletsService()
      )
      _backupStore = backupStore
      return backupStore
    }
  }
  
  private struct NftsStoreWeakWrapper {
    weak var nftsStore: NftsStore?
  }
  private var nftsStores = [Wallet: NftsStoreWeakWrapper]()
  
  func nftsStore(wallet: Wallet) -> NftsStore {
    nftsStores = nftsStores.filter { $0.value.nftsStore != nil }
    if let nftsStore = nftsStores[wallet]?.nftsStore {
      return nftsStore
    } else {
      let store = NftsStore(
        loadPaginator: NftsLoadPaginator(
          wallet: wallet,
          accountNftsService: servicesAssembly.accountNftService()
        )
      )
      nftsStores[wallet] = NftsStoreWeakWrapper(nftsStore: store)
      return store
    }
  }
  
  private weak var _securityStore: SecurityStore?
  var securityStore: SecurityStore {
    if let securityStore = _securityStore {
      return securityStore
    } else {
      let securityStore = SecurityStore(securityService: servicesAssembly.securityService())
      _securityStore = securityStore
      return securityStore
    }
  }
  
  private weak var _setupStore: SetupStore?
  var setupStore: SetupStore {
    if let setupStore = _setupStore {
      return setupStore
    } else {
      let setupStore = SetupStore(setupService: servicesAssembly.setupService())
      _setupStore = setupStore
      return setupStore
    }
  }
  
  private weak var _backgroundUpdateStore: BackgroundUpdateStore?
  var backgroundUpdateStore: BackgroundUpdateStore {
    if let backgroundUpdateStore = _backgroundUpdateStore {
      return backgroundUpdateStore
    } else {
      let backgroundUpdateStore = BackgroundUpdateStore(
        streamingAPI: apiAssembly.streamingTonAPIClient()
      )
      _backgroundUpdateStore = backgroundUpdateStore
      return backgroundUpdateStore
    }
  }
  
  private weak var _tonConnectAppsStore: TonConnectAppsStore?
  var tonConnectAppsStore: TonConnectAppsStore {
    if let tonConnectAppsStore = _tonConnectAppsStore {
      return tonConnectAppsStore
    } else {
      let tonConnectAppsStore = TonConnectAppsStore(
        tonConnectService: servicesAssembly.tonConnectService()
      )
      _tonConnectAppsStore = tonConnectAppsStore
      return tonConnectAppsStore
    }
  }
}
