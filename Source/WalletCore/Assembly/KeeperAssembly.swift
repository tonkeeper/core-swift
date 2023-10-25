//
//  KeeperAssembly.swift
//  
//
//  Created by Grigory Serebryanyy on 24.10.2023.
//

import Foundation

final class KeeperAssembly {
    let coreAssembly: CoreAssembly
    let servicesAssembly: ServicesAssembly
    let keychainGroup: String
    
    init(coreAssembly: CoreAssembly,
         servicesAssembly: ServicesAssembly,
         keychainGroup: String) {
        self.coreAssembly = coreAssembly
        self.servicesAssembly = servicesAssembly
        self.keychainGroup = keychainGroup
    }
    
    lazy var keeperController: KeeperController = {
        KeeperController(keeperService: servicesAssembly.keeperInfoService,
                         keychainManager: coreAssembly.keychainManager,
                         keychainGroup: keychainGroup)
    }()
}
