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
    let storesAssembly: StoresAssembly
    let cacheURL: URL
    
    init(coreAssembly: CoreAssembly,
         apiAssembly: APIAssembly,
         servicesAssembly: ServicesAssembly,
         formattersAssembly: FormattersAssembly,
         storesAssembly: StoresAssembly,
         cacheURL: URL) {
        self.coreAssembly = coreAssembly
        self.apiAssembly = apiAssembly
        self.servicesAssembly = servicesAssembly
        self.formattersAssembly = formattersAssembly
        self.storesAssembly = storesAssembly
        self.cacheURL = cacheURL
    }
    
    var activityListController: ActivityListController {
        ActivityListController(
            activityListLoader: activityListLoader(),
            collectiblesService: servicesAssembly.collectiblesService,
            walletProvider: coreAssembly.walletProvider,
            activityEventMapper: activityEventMapper(),
            dateFormatter: formattersAssembly.dateFormatter
        )
    }
    
    var activityListTonEventsController: ActivityListController {
        ActivityListController(activityListLoader: activityListTonEventsLoader(),
                               collectiblesService: servicesAssembly.collectiblesService,
                               walletProvider: coreAssembly.walletProvider,
                               activityEventMapper: activityEventMapper(),
                               dateFormatter: formattersAssembly.dateFormatter
        )
    }
    
    func activityListTokenEventsController(tokenInfo: TokenInfo) -> ActivityListController {
        return ActivityListController(
            activityListLoader: activityListTokenEventsLoader(
                tokenInfo: tokenInfo
            ),
            collectiblesService: servicesAssembly.collectiblesService,
            walletProvider: coreAssembly.walletProvider,
            activityEventMapper: activityEventMapper(),
            dateFormatter: formattersAssembly.dateFormatter
        )
    }
    
    func activityController() -> ActivityController {
        ActivityController(collectiblesService: servicesAssembly.collectiblesService)
    }
    
    func activityEventDetailsController(action: ActivityEventAction) -> ActivityEventDetailsController {
        let amountMapper = SignedAmountAccountEventActionAmountMapper(
            amountAccountEventActionAmountMapper: AmountAccountEventActionAmountMapper(
                amountFormatter: formattersAssembly.amountFormatter
            )
        )
        return ActivityEventDetailsController(
            action: action,
            amountMapper: amountMapper,
            ratesStore: storesAssembly.ratesStore,
            walletProvider: coreAssembly.walletProvider,
            collectiblesService: servicesAssembly.collectiblesService
        )
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
