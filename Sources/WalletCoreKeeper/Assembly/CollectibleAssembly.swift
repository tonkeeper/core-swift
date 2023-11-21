//
//  CollectibleAssembly.swift
//  
//
//  Created by Grigory on 22.8.23..
//

import Foundation
import TonSwift
import WalletCoreCore

struct CollectibleAssembly {
    let servicesAssembly: ServicesAssembly
    let formattersAssembly: FormattersAssembly
    
    init(servicesAssembly: ServicesAssembly,
         formattersAssembly: FormattersAssembly) {
        self.servicesAssembly = servicesAssembly
        self.formattersAssembly = formattersAssembly
    }
    
    func collectibleDetailsController(collectibleAddress: Address,
                                      walletProvider: WalletProvider,
                                      contractBuilder: WalletContractBuilder) -> CollectibleDetailsController {
        CollectibleDetailsController(collectibleAddress: collectibleAddress,
                                     walletProvider: walletProvider,
                                     contractBuilder: contractBuilder,
                                     collectiblesService: servicesAssembly.collectiblesService,
                                     dnsService: servicesAssembly.dnsService,
                                     collectibleDetailsMapper: CollectibleDetailsMapper(dateFormatter: formattersAssembly.dateFormatter))
    }
}
