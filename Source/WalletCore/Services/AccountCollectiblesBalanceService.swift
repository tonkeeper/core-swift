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
            return try? mapNFTItemToCollectible(nft: nft)
        }

        return collectibles
    }
}

private extension AccountCollectiblesBalanceServiceImplementation {
    func mapNFTItemToCollectible(nft: NFTItem) throws -> Collectible {
        let address = try Address.parse(nft.address)
        var name: String?
        var imageURL: URL?
        var description: String?
        var collection: Collection?
        if case let .string(string) = nft.metadata["name"] {
            name = string
        }
        if case let .string(string) = nft.metadata["image"] {
            imageURL = URL(string: string)
        }
        if case let .string(string) = nft.metadata["description"] {
            description = string
        }
        if let nftCollection = nft.collection,
           let address = try? Address.parse(nftCollection.address) {
            collection = Collection(address: address, name: nftCollection.name)
        }
        
        return Collectible(address: address,
                           name: name,
                           imageURL: imageURL,
                           description: description,
                           collection: collection)
    }
}
