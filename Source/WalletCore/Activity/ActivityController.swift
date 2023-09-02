//
//  ActivityController.swift
//
//
//  Created by Grigory on 3.9.23..
//

import Foundation
import TonSwift

public final class ActivityController {
    
    private let collectiblesService: CollectiblesService
    
    init(collectiblesService: CollectiblesService) {
        self.collectiblesService = collectiblesService
    }
    
    public func isNeedToLoadNFT(with address: Address) -> Bool {
        do {
            try _ = collectiblesService.getCollectible(address: address)
            return false
        } catch {
            return true
        }
    }
    
    public func loadNFT(with address: Address) async throws {
        _ = try await collectiblesService.loadCollectibles(addresses: [address])
    }
}
