//
//  KeeperInfoService.swift
//  
//
//  Created by Grigory on 27.6.23..
//

import Foundation

protocol KeeperInfoService {
    func getKeeperInfo() throws -> KeeperInfo
    func saveKeeperInfo(_ keeperInfo: KeeperInfo) throws
}

enum KeeperServiceError: Swift.Error {
    case failedToGetKeeperInfo(Swift.Error)
}

final class KeeperInfoServiceImplementation: KeeperInfoService {
    
    private let localRepository: LocalDiskRepository<KeeperInfo>

    init(localRepository: LocalDiskRepository<KeeperInfo>) {
        self.localRepository = localRepository
    }

    func getKeeperInfo() throws -> KeeperInfo {
        do {
            return try localRepository.load()
        } catch {
            throw KeeperServiceError.failedToGetKeeperInfo(error)
        }
    }

    func saveKeeperInfo(_ keeperInfo: KeeperInfo) throws {
        try localRepository.save(item: keeperInfo)
    }
}
