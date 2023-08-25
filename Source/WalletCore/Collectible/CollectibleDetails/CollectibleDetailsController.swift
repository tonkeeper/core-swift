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
    private let collectibleDetailsMapper: CollectibleDetailsMapper
    
    init(collectibleAddress: Address,
         collectiblesService: CollectiblesService,
         collectibleDetailsMapper: CollectibleDetailsMapper) {
        self.collectibleAddress = collectibleAddress
        self.collectiblesService = collectiblesService
        self.collectibleDetailsMapper = collectibleDetailsMapper
    }
    
    public func getCollectibleModel() throws -> CollectibleDetailsViewModel {
        let collectible = try collectiblesService.getCollectible(address: collectibleAddress)
        let viewModel = collectibleDetailsMapper.map(collectible: collectible)
        return viewModel
    }
}
