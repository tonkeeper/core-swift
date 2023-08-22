//
//  CollectibleDetailsController.swift
//  
//
//  Created by Grigory on 22.8.23..
//

import Foundation
import TonSwift

public final class CollectibleDetailsController {
    
    private let collectibleAddress: Address
    private let collectiblesService: CollectiblesService
    
    init(collectibleAddress: Address,
         collectiblesService: CollectiblesService) {
        self.collectibleAddress = collectibleAddress
        self.collectiblesService = collectiblesService
    }
}
