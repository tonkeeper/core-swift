import Foundation
import TonSwift

public final class StoresAssembly {
  
  private let servicesAssembly: ServicesAssembly
  
  init(servicesAssembly: ServicesAssembly) {
    self.servicesAssembly = servicesAssembly
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
}
