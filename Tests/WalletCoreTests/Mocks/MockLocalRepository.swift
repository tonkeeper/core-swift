//
//  MockLocalRepository.swift
//  
//
//  Created by Grigory on 27.6.23..
//

import Foundation
@testable import WalletCore

final class MockLocalRepository: LocalRepository {
    var keeperInfo: KeeperInfo?
    
    func load(fileName: String) throws -> WalletCore.KeeperInfo {
        guard let keeperInfo = keeperInfo else {
            throw NSError(domain: "", code: 1)
        }
        return keeperInfo
    }
    
    func save(item: KeeperInfo) throws {
        keeperInfo = item
    }
}
