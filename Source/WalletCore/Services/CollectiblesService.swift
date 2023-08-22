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
        address.toString()
    }
}

protocol CollectiblesService {
    func loadCollectibles(addresses: [Address]) async throws -> Collectibles
    func getCollectibles() throws -> Collectibles
    func getCollectible(address: Address) throws -> Collectible
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
        let request = NFTsBulkRequest(nftsAddresses: addresses.map { $0.toString() })
        let response = try await api.send(request: request)
        var collectibles = [Address: Collectible]()
        for item in response.entity.nftItems {
            guard let collectible = try? Collectible(nftItem: item) else { continue }
            try? localRepository.save(item: collectible)
            collectibles[collectible.address] = collectible
        }
        return .init(collectibles: collectibles)
    }
    
    func getCollectibles() throws -> Collectibles {
        let collectibles = try localRepository.loadAll()
        let collectiblesDictionary = collectibles.reduce(into: [Address: Collectible]()) { result, collectible in
            result[collectible.address] = collectible
        }
        return Collectibles(collectibles: collectiblesDictionary)
    }
    
    func getCollectible(address: Address) throws -> Collectible {
        return try localRepository.load(key: address.toString())
    }
}


