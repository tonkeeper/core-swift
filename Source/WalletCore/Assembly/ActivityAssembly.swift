//
//  ActivityAssembly.swift
//  
//
//  Created by Grigory on 4.8.23..
//

import Foundation
import TonAPI

struct ActivityAssembly {
    let formattersAssembly: FormattersAssembly
    let coreAssembly: CoreAssembly
    
    init(coreAssembly: CoreAssembly,
         formattersAssembly: FormattersAssembly) {
        self.coreAssembly = coreAssembly
        self.formattersAssembly = formattersAssembly
    }
    
    func activityListController(api: API,
                                walletProvider: WalletProvider,
                                cacheURL: URL) -> ActivityListController {
        return ActivityListController(activityService: activityService(api: api, cacheURL: cacheURL),
                                      walletProvider: walletProvider,
                                      contractBuilder: WalletContractBuilder(),
                                      activityEventMapper: activityEventMapper()
        )
    }
}

private extension ActivityAssembly {
    func activityService(api: API, cacheURL: URL) -> ActivityService {
        ActivityServiceImplementation(api: api)
    }
    
    func activityEventMapper() -> ActivityEventMapper {
        ActivityEventMapper(dateFormatter: formattersAssembly.dateFormatter)
    }
}
