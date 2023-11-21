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
    let cacheURL: URL
    
    init(coreAssembly: CoreAssembly,
         apiAssembly: APIAssembly,
         servicesAssembly: ServicesAssembly,
         formattersAssembly: FormattersAssembly,
         cacheURL: URL) {
        self.coreAssembly = coreAssembly
        self.apiAssembly = apiAssembly
        self.servicesAssembly = servicesAssembly
        self.formattersAssembly = formattersAssembly
        self.cacheURL = cacheURL
    }
    
    var activityListController: ActivityListController {
        ActivityListController(
            activityListLoader: activityListLoader(),
            collectiblesService: servicesAssembly.collectiblesService,
            walletProvider: coreAssembly.walletProvider,
            contractBuilder: WalletContractBuilder(),
            activityEventMapper: activityEventMapper(),
            dateFormatter: formattersAssembly.dateFormatter,
            transactionsUpdatePublishService: servicesAssembly.transactionsUpdateService
        )
    }
    
    var activityListTonEventsController: ActivityListController {
        ActivityListController(activityListLoader: activityListTonEventsLoader(),
                               collectiblesService: servicesAssembly.collectiblesService,
                               walletProvider: coreAssembly.walletProvider,
                               contractBuilder: WalletContractBuilder(),
                               activityEventMapper: activityEventMapper(),
                               dateFormatter: formattersAssembly.dateFormatter,
                               transactionsUpdatePublishService: servicesAssembly.transactionsUpdateService
        )
    }
    
    func activityListTokenEventsController(tokenInfo: TokenInfo) -> ActivityListController {
        return ActivityListController(
            activityListLoader: activityListTokenEventsLoader(
                tokenInfo: tokenInfo
            ),
            collectiblesService: servicesAssembly.collectiblesService,
            walletProvider: coreAssembly.walletProvider,
            contractBuilder: WalletContractBuilder(),
            activityEventMapper: activityEventMapper(),
            dateFormatter: formattersAssembly.dateFormatter,
            transactionsUpdatePublishService: servicesAssembly.transactionsUpdateService
        )
    }
    
    func activityController() -> ActivityController {
        ActivityController(collectiblesService: servicesAssembly.collectiblesService)
    }
}

private extension ActivityAssembly {
    func activityEventMapper() -> AccountEventMapper {
        let amountMapper = SignedAmountAccountEventActionAmountMapper(
            amountAccountEventActionAmountMapper: AmountAccountEventActionAmountMapper(
                amountFormatter: formattersAssembly.amountFormatter
            )
        )
        return AccountEventMapper(dateFormatter: formattersAssembly.dateFormatter,
                                  amountFormatter: formattersAssembly.amountFormatter,
                                  intAmountFormatter: formattersAssembly.intAmountFormatter,
                                  amountMapper: amountMapper
        )
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
