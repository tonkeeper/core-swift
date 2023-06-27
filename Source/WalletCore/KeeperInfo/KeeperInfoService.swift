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

final class KeeperInfoServiceImplementation: KeeperInfoService {
    
    private let localRepository: LocalDiskRepository<KeeperInfo>

    init(localRepository: LocalDiskRepository<KeeperInfo>) {
        self.localRepository = localRepository
    }

    func getKeeperInfo() throws -> KeeperInfo {
        try localRepository.load()
    }

    func saveKeeperInfo(_ keeperInfo: KeeperInfo) throws {
        try localRepository.save(item: keeperInfo)
    }
}
