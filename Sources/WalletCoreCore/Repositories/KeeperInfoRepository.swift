//
//  KeeperInfoRepository.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation

public protocol KeeperInfoRepository {
    func getKeeperInfo() throws -> KeeperInfo
    func saveKeeperInfo(_ keeperInfo: KeeperInfo) throws
    func removeKeeperInfo() throws
}
