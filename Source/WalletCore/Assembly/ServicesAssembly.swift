//
//  ServicesAssembly.swift
//  
//
//  Created by Grigory on 22.8.23..
//

import Foundation
import TonAPI

final class ServicesAssembly {
    let coreAssembly: CoreAssembly
    let apiAssembly: APIAssembly
    let cacheURL: URL
    let sharedCacheURL: URL
    
    init(coreAssembly: CoreAssembly,
         apiAssembly: APIAssembly,
         cacheURL: URL,
         sharedCacheURL: URL) {
        self.coreAssembly = coreAssembly
        self.apiAssembly = apiAssembly
        self.cacheURL = cacheURL
        self.sharedCacheURL = sharedCacheURL
    }
    
    var keeperInfoService: KeeperInfoService {
        KeeperInfoServiceImplementation(localRepository: localRepository(cacheURL: sharedCacheURL))
    }

    var collectiblesService: CollectiblesService {
        CollectiblesServiceImplementation(
            api: apiAssembly.api,
            localRepository: localRepository(cacheURL: cacheURL)
        )
    }
    
    var ratesService: RatesService {
        RatesServiceImplementation(
            api: apiAssembly.api,
            localRepository: localRepository(cacheURL: cacheURL)
        )
    }
    
    var sendService: SendService {
        SendServiceImplementation(api: apiAssembly.api)
    }
    
    var walletBalanceService: WalletBalanceService {
        WalletBalanceServiceImplementation(
            tonBalanceService: tonBalanceService,
            tokensBalanceService: tokensBalanceService,
            collectiblesService: collectiblesService,
            walletContractBuilder: WalletContractBuilder(),
            localRepository: localRepository(cacheURL: cacheURL))
    }
    
    var tonBalanceService: AccountTonBalanceService {
        AccountTonBalanceServiceImplementation(api: apiAssembly.api)
    }
    
    var tokensBalanceService: AccountTokensBalanceService {
        AccountTokensBalanceServiceImplementation(api: apiAssembly.api)
    }
    
    var accountInfoService: AccountInfoService {
        AccountInfoServiceImplementation(api: apiAssembly.api)
    }
    
    var activityService: ActivityService {
        ActivityServiceImplementation(api: apiAssembly.api)
    }
    
    var chartService: ChartService {
        ChartServiceImplementation(api: apiAssembly.legacyAPI)
    }
    
    var dnsService: DNSService {
        DNSServiceImplementation(api: apiAssembly.api)
    }
    
    var fiatMethodsService: FiatMethodsService {
        FiatMethodsServiceImplementation(
            api: apiAssembly.legacyAPI,
            localRepository: localRepository(cacheURL: cacheURL)
        )
    }
    
    lazy var transactionsUpdateService: TransactionsUpdateService = {
        TransactionsUpdateServiceImplementation(streamingAPI: apiAssembly.streamingTonAPIClient())
    }()
}

private extension ServicesAssembly {
    func localRepository<T: LocalStorable>(cacheURL: URL) -> any LocalRepository<T> {
        LocalDiskRepository(fileManager: coreAssembly.fileManager,
                            directory: cacheURL,
                            encoder: coreAssembly.encoder,
                            decoder: coreAssembly.decoder)
    }
}
