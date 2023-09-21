//
//  ActivityAssembly.swift
//
//
//  Created by Grigory on 4.8.23..
//

import Foundation
import TonAPI

struct ActivityAssembly {
    let servicesAssembly: ServicesAssembly
    let formattersAssembly: FormattersAssembly
    let coreAssembly: CoreAssembly
    
    init(servicesAssembly: ServicesAssembly,
         coreAssembly: CoreAssembly,
         formattersAssembly: FormattersAssembly) {
        self.servicesAssembly = servicesAssembly
        self.coreAssembly = coreAssembly
        self.formattersAssembly = formattersAssembly
    }
    
    func activityListController(api: API,
                                walletProvider: WalletProvider,
                                cacheURL: URL) -> ActivityListController {
        return ActivityListController(activityListLoader: activityListLoader(api: api, cacheURL: cacheURL),
                                      collectiblesService: collectiblesService(api: api, cacheURL: cacheURL),
                                      walletProvider: walletProvider,
                                      contractBuilder: WalletContractBuilder(),
                                      activityEventMapper: activityEventMapper(),
                                      transactionsUpdatePublishService: servicesAssembly.transactionsUpdateService
        )
    }
    
    func activityListTonEventsController(api: API,
                                         walletProvider: WalletProvider,
                                         cacheURL: URL) -> ActivityListController {
        return ActivityListController(activityListLoader: activityListTonEventsLoader(api: api, cacheURL: cacheURL),
                                      collectiblesService: collectiblesService(api: api, cacheURL: cacheURL),
                                      walletProvider: walletProvider,
                                      contractBuilder: WalletContractBuilder(),
                                      activityEventMapper: activityEventMapper(),
                                      transactionsUpdatePublishService: servicesAssembly.transactionsUpdateService
        )
    }
    
    func activityListTokenEventsController(api: API,
                                           walletProvider: WalletProvider,
                                           cacheURL: URL,
                                           tokenInfo: TokenInfo) -> ActivityListController {
        return ActivityListController(activityListLoader: activityListTokenEventsLoader(api: api,
                                                                                        cacheURL: cacheURL,
                                                                                        tokenInfo: tokenInfo),
                                      collectiblesService: collectiblesService(api: api, cacheURL: cacheURL),
                                      walletProvider: walletProvider,
                                      contractBuilder: WalletContractBuilder(),
                                      activityEventMapper: activityEventMapper(),
                                      transactionsUpdatePublishService: servicesAssembly.transactionsUpdateService
        )
    }
    
    func activityController() -> ActivityController {
        ActivityController(collectiblesService: servicesAssembly.collectiblesService)
    }
}

private extension ActivityAssembly {
    func activityService(api: API, cacheURL: URL) -> ActivityService {
        ActivityServiceImplementation(api: api)
    }
    
    func collectiblesService(api: API, cacheURL: URL) -> CollectiblesService {
        CollectiblesServiceImplementation(api: api,
                                          localRepository: localRepository(cacheURL: cacheURL))
    }
    
    func activityEventMapper() -> ActivityEventMapper {
        ActivityEventMapper(dateFormatter: formattersAssembly.dateFormatter,
                            bigIntFormatter: formattersAssembly.bigIntAmountFormatter,
                            intAmountFormatter: formattersAssembly.intAmountFormatter)
    }
    
    func localRepository(cacheURL: URL) -> any LocalRepository<Collectible> {
        LocalDiskRepository(fileManager: coreAssembly.fileManager,
                            directory: cacheURL,
                            encoder: coreAssembly.encoder,
                            decoder: coreAssembly.decoder)
    }
    
    func activityListLoader(api: API, cacheURL: URL) -> ActivityListLoader {
        ActivityListAllEventsLoader(activityService: activityService(api: api, cacheURL: cacheURL))
    }
    
    func activityListTonEventsLoader(api: API, cacheURL: URL) -> ActivityListLoader {
        ActivityListTonEventsLoader(activityService: activityService(api: api, cacheURL: cacheURL))
    }
    
    func activityListTokenEventsLoader(api: API, cacheURL: URL, tokenInfo: TokenInfo) -> ActivityListLoader {
        ActivityListTokenEventsLoader(
            tokenInfo: tokenInfo,
            activityService: activityService(api: api, cacheURL: cacheURL)
        )
    }
}
