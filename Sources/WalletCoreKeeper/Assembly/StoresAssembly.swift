import Foundation

final class StoresAssembly {
    
    let servicesAssembly: ServicesAssembly
    let coreAssembly: CoreAssembly
    
    private weak var _balanceStore: BalanceStore?
    private weak var _ratesStore: RatesStore?
    
    init(servicesAssembly: ServicesAssembly, 
         coreAssembly: CoreAssembly) {
        self.servicesAssembly = servicesAssembly
        self.coreAssembly = coreAssembly
    }
    
    var balanceStore: BalanceStore {
        if let _balanceStore = _balanceStore {
            return _balanceStore
        }
        let balanceStore =  BalanceStore(
            balanceService: servicesAssembly.balanceService,
            walletProvider: coreAssembly.walletProvider
        )
        self._balanceStore = balanceStore
        return balanceStore
    }
    
    var ratesStore: RatesStore {
        if let _ratesStore = _ratesStore {
            return _ratesStore
        }
        let ratesStore = RatesStore(
            ratesService: servicesAssembly.ratesService,
            walletProvider: coreAssembly.walletProvider
        )
        self._ratesStore = ratesStore
        return ratesStore
    }
}
