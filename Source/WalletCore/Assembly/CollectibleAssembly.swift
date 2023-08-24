//
//  CollectibleAssembly.swift
//  
//
//  Created by Grigory on 22.8.23..
//

import Foundation
import TonSwift

struct CollectibleAssembly {
    let servicesAssembly: ServicesAssembly
    
    init(servicesAssembly: ServicesAssembly) {
        self.servicesAssembly = servicesAssembly
    }
    
    func collectibleDetailsController(collectibleAddress: Address) -> CollectibleDetailsController {
        CollectibleDetailsController(collectibleAddress: collectibleAddress,
                                     collectiblesService: servicesAssembly.collectiblesService,
                                     collectibleDetailsMapper: CollectibleDetailsMapper())
    }
}
