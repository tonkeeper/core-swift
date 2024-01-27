import Foundation

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
}
