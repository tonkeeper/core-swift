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
    let formattersAssembly: FormattersAssembly
    
    init(coreAssembly: CoreAssembly,
         formattersAssembly: FormattersAssembly) {
        self.coreAssembly = coreAssembly
        self.formattersAssembly = formattersAssembly
    }
    
    func walletBalanceService(api: API, cacheURL: URL) -> WalletBalanceService {
        WalletBalanceServiceImplementation(
            tonBalanceService: tonBalanceService(api: api),
            tokensBalanceService: tokensBalanceService(api: api),
            walletContractBuilder: walletContractBuilder(),
            localRepository: localRepository(cacheURL: cacheURL))
    }
    
    func walletBalanceMapper() -> WalletBalanceMapper {
        WalletBalanceMapper(intAmountFormatter: formattersAssembly.intAmountFormatter,
                            decimalAmountFormatter: formattersAssembly.decimalAmountFormatter,
                            bigIntAmountFormatter: formattersAssembly.bigIntAmountFormatter,
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
    
    func walletContractBuilder() -> WalletContractBuilder {
        WalletContractBuilder()
    }
    
    func rateConverter() -> RateConverter {
        RateConverter()
    }
}
