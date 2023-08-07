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
    
    init(coreAssembly: CoreAssembly) {
        self.coreAssembly = coreAssembly
    }
    
    func activityListController(api: API,
                                walletProvider: WalletProvider,
                                cacheURL: URL) -> ActivityListController {
        return ActivityListController(activityService: activityService(api: api, cacheURL: cacheURL),
                                      walletProvider: walletProvider,
                                      contractBuilder: WalletContractBuilder())
    }
}

private extension ActivityAssembly {
    func activityService(api: API, cacheURL: URL) -> ActivityService {
        ActivityServiceImplementation(api: api)
    }
}
