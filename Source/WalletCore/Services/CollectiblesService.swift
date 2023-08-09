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
    let collectibles: [Address: Collectible]
    
    static var fileName: String {
        String(describing: self)
    }
    
    var fileName: String {
        String(describing: type(of: self))
    }
}

protocol CollectiblesService {
    func loadCollectibles(addresses: [Address]) async throws -> Collectibles
    func getCollectibles() throws -> Collectibles
}

final class CollectiblesServiceImplementation: CollectiblesService {
    private let api: API
    private let localRepository: any LocalRepository<Collectibles>
    
    init(api: API,
         localRepository: any LocalRepository<Collectibles>) {
        self.api = api
        self.localRepository = localRepository
    }
    
    func loadCollectibles(addresses: [Address]) async throws -> Collectibles {
        let request = NFTsBulkRequest(nftsAddresses: addresses.map { $0.toString() })
        let response = try await api.send(request: request)
        var collectibles = [Address: Collectible]()
        for item in response.entity.nftItems {
            guard let collectible = try? Collectible(nftItem: item) else { continue }
            collectibles[collectible.address] = collectible
        }
        try? localRepository.save(item: .init(collectibles: collectibles))
        return .init(collectibles: collectibles)
    }
    
    func getCollectibles() throws -> Collectibles {
        return try localRepository.load(fileName: Collectibles.fileName)
    }
}


