//
//  WalletBalanceAssembly.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation
import TonAPI

final class WalletBalanceAssembly {
    let coreAssembly: CoreAssembly
    let servicesAssembly: ServicesAssembly
    let formattersAssembly: FormattersAssembly
    
    init(coreAssembly: CoreAssembly,
         servicesAssembly: ServicesAssembly,
         formattersAssembly: FormattersAssembly) {
        self.coreAssembly = coreAssembly
        self.servicesAssembly = servicesAssembly
        self.formattersAssembly = formattersAssembly
    }
    
    func walletBalanceService(api: API, cacheURL: URL) -> WalletBalanceService {
        WalletBalanceServiceImplementation(
            tonBalanceService: tonBalanceService(api: api),
            tokensBalanceService: tokensBalanceService(api: api),
            collectiblesService: servicesAssembly.collectiblesService,
            walletContractBuilder: walletContractBuilder(),
            localRepository: localRepository(cacheURL: cacheURL))
    }
    
    func walletBalanceMapper() -> WalletBalanceMapper {
        let walletItemMapper = WalletItemMapper(intAmountFormatter: formattersAssembly.intAmountFormatter,
                                                amountFormatter: formattersAssembly.amountFormatter,
                                                decimalAmountFormatter: formattersAssembly.decimalAmountFormatter,
                                                rateConverter: rateConverter())
        
        return WalletBalanceMapper(walletItemMapper: walletItemMapper,
                                   amountFormatter: formattersAssembly.amountFormatter,
                                   rateConverter: rateConverter())
    }
}

private extension WalletBalanceAssembly {
    func localRepository(cacheURL: URL) -> any LocalRepository<WalletBalance> {
        return LocalDiskRepository(fileManager: coreAssembly.fileManager,
                                   directory: cacheURL,
                                   encoder: coreAssembly.encoder,
                                   decoder: coreAssembly.decoder)
    }
    
    func tonBalanceService(api: API) -> AccountTonBalanceService {
        AccountTonBalanceServiceImplementation(api: api)
    }
    
    func tokensBalanceService(api: API) -> AccountTokensBalanceService {
        AccountTokensBalanceServiceImplementation(api: api)
    }
    
    func collectiblesBalanceService(api: API) -> AccountCollectiblesBalanceService {
        AccountCollectiblesBalanceServiceImplementation(api: api)
    }
    
    func walletContractBuilder() -> WalletContractBuilder {
        WalletContractBuilder()
    }
    
    func rateConverter() -> RateConverter {
        RateConverter()
    }
}
