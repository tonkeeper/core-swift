//
//  AccountNFTsBalanceService.swift
//  
//
//  Created by Grigory on 1.7.23..
//

import Foundation
import TonSwift
import TonAPI

protocol AccountCollectiblesBalanceService {
    func loadCollectibles(address: Address,
                          collectionAddress: Address?,
                          limit: Int,
                          offset: Int,
                          isIndirectOwnership: Bool) async throws -> [Collectible]
}

final class AccountCollectiblesBalanceServiceImplementation: AccountCollectiblesBalanceService {
    
    private let api: API
    
    init(api: API) {
        self.api = api
    }
    
    func loadCollectibles(address: Address,
                          collectionAddress: Address?,
                          limit: Int,
                          offset: Int,
                          isIndirectOwnership: Bool) async throws -> [Collectible] {
        let request = AccountNFTsRequest(
            accountId: address.toRaw(),
            collection: collectionAddress?.toRaw(),
            limit: limit,
            offset: offset,
            isIndirectOwnership: isIndirectOwnership)
        let response = try await api.send(request: request)
        
        let collectibles = response.entity.nftItems.compactMap { nft in
            return try? Collectible(nftItem: nft)
        }

        return collectibles
    }
}

