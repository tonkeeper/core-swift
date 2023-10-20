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
    func removeKeeperInfo() throws
}

enum KeeperServiceError: Swift.Error {
    case failedToGetKeeperInfo(Swift.Error)
}

final class KeeperInfoServiceImplementation: KeeperInfoService {
    
    private let localRepository: any LocalRepository<KeeperInfo>

    init(localRepository: any LocalRepository<KeeperInfo>) {
        self.localRepository = localRepository
    }

    func getKeeperInfo() throws -> KeeperInfo {
        do {
            return try localRepository.load(fileName: KeeperInfo.fileName)
        } catch {
            throw KeeperServiceError.failedToGetKeeperInfo(error)
        }
    }

    func saveKeeperInfo(_ keeperInfo: KeeperInfo) throws {
        try localRepository.save(item: keeperInfo)
    }
    
    func removeKeeperInfo() throws {
        try localRepository.remove(fileName: KeeperInfo.fileName)
    }
}
