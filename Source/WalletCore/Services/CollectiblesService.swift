//
//  CollectiblesService.swift
//  
//
//  Created by Grigory on 9.8.23..
//

import Foundation
import TonAPI
import TonSwift

struct Collectibles: LocalStorable {
    typealias KeyType = String
    
    let collectibles: [Address: Collectible]
    
    var key: String {
        fileName
    }
}

extension Collectible: LocalStorable {
    typealias KeyType = String
    var key: String {
        address.toRaw()
    }
}

protocol CollectiblesService {
    func loadCollectibles(addresses: [Address]) async throws -> Collectibles
    func getCollectibles() throws -> Collectibles
    func getCollectible(address: Address) throws -> Collectible
    func saveCollectible(collectible: Collectible) throws
    func loadCollectibles(address: Address,
                          collectionAddress: Address?,
                          limit: Int,
                          offset: Int,
                          isIndirectOwnership: Bool) async throws -> [Collectible]
}

final class CollectiblesServiceImplementation: CollectiblesService {
    private let api: API
    private let localRepository: any LocalRepository<Collectible>
    
    init(api: API,
         localRepository: any LocalRepository<Collectible>) {
        self.api = api
        self.localRepository = localRepository
    }
    
    func loadCollectibles(addresses: [Address]) async throws -> Collectibles {
        let nfts = try await api.getNftItemsByAddresses(addresses)
        var collectibles = [Address: Collectible]()
        nfts.forEach {
            try? localRepository.save(item: $0)
            collectibles[$0.address] = $0
        }
        return .init(collectibles: collectibles)
    }
    
    func loadCollectibles(address: Address,
                          collectionAddress: Address?,
                          limit: Int,
                          offset: Int,
                          isIndirectOwnership: Bool) async throws -> [Collectible] {
        let nfts = try await api.getAccountNftItems(
            address: address,
            collectionAddress: collectionAddress,
            limit: limit,
            offset: offset,
            isIndirectOwnership: isIndirectOwnership)
        nfts.forEach {
            try? localRepository.save(item: $0)
        }

        return nfts
    }
    
    func getCollectibles() throws -> Collectibles {
        let collectibles = try localRepository.loadAll()
        let collectiblesDictionary = collectibles.reduce(into: [Address: Collectible]()) { result, collectible in
            result[collectible.address] = collectible
        }
        return Collectibles(collectibles: collectiblesDictionary)
    }
    
    func getCollectible(address: Address) throws -> Collectible {
        return try localRepository.load(key: address.toRaw())
    }
    
    func saveCollectible(collectible: Collectible) throws {
        try localRepository.save(item: collectible)
    }
}


