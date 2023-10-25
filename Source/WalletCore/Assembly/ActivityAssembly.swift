//
//  ActivityAssembly.swift
//
//
//  Created by Grigory on 4.8.23..
//

import Foundation
import TonAPI

struct ActivityAssembly {
    let coreAssembly: CoreAssembly
    let apiAssembly: APIAssembly
    let servicesAssembly: ServicesAssembly
    let formattersAssembly: FormattersAssembly
    let keeperAssembly: KeeperAssembly
    let cacheURL: URL
    
    init(coreAssembly: CoreAssembly,
         apiAssembly: APIAssembly,
         servicesAssembly: ServicesAssembly,
         formattersAssembly: FormattersAssembly,
         keeperAssembly: KeeperAssembly,
         cacheURL: URL) {
        self.coreAssembly = coreAssembly
        self.apiAssembly = apiAssembly
        self.servicesAssembly = servicesAssembly
        self.formattersAssembly = formattersAssembly
        self.keeperAssembly = keeperAssembly
        self.cacheURL = cacheURL
    }
    
    var activityListController: ActivityListController {
        ActivityListController(
            activityListLoader: activityListLoader(),
            collectiblesService: servicesAssembly.collectiblesService,
            walletProvider: keeperAssembly.keeperController,
            contractBuilder: WalletContractBuilder(),
            activityEventMapper: activityEventMapper(),
            transactionsUpdatePublishService: servicesAssembly.transactionsUpdateService
        )
    }
    
    var activityListTonEventsController: ActivityListController {
        ActivityListController(activityListLoader: activityListTonEventsLoader(),
                               collectiblesService: servicesAssembly.collectiblesService,
                               walletProvider: keeperAssembly.keeperController,
                               contractBuilder: WalletContractBuilder(),
                               activityEventMapper: activityEventMapper(),
                               transactionsUpdatePublishService: servicesAssembly.transactionsUpdateService
        )
    }
    
    func activityListTokenEventsController(tokenInfo: TokenInfo) -> ActivityListController {
        return ActivityListController(
            activityListLoader: activityListTokenEventsLoader(
                tokenInfo: tokenInfo
            ),
            collectiblesService: servicesAssembly.collectiblesService,
            walletProvider: keeperAssembly.keeperController,
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
    func activityEventMapper() -> ActivityEventMapper {
        ActivityEventMapper(dateFormatter: formattersAssembly.dateFormatter,
                            amountFormatter: formattersAssembly.amountFormatter,
                            intAmountFormatter: formattersAssembly.intAmountFormatter)
    }
    
    func activityListLoader() -> ActivityListLoader {
        ActivityListAllEventsLoader(activityService: servicesAssembly.activityService)
    }
    
    func activityListTonEventsLoader() -> ActivityListLoader {
        ActivityListTonEventsLoader(activityService: servicesAssembly.activityService)
    }
    
    func activityListTokenEventsLoader(tokenInfo: TokenInfo) -> ActivityListLoader {
        ActivityListTokenEventsLoader(
            tokenInfo: tokenInfo,
            activityService: servicesAssembly.activityService
        )
    }
}
