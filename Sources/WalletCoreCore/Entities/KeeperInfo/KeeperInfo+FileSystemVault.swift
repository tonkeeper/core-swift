//
//  KeeperInfo+FileSystemVault.swift
//
//
//  Created by Grigory Serebryanyy on 20.11.2023.
//

import Foundation

extension KeeperInfo: KeyValueVaultValue {
    var key: String {
        String(describing: type(of: self))
    }
    
    typealias Key = String
}

extension FileSystemVault: KeeperInfoRepository where T == KeeperInfo {
    func getKeeperInfo() throws -> KeeperInfo {
        try loadValue(key: String(describing: T.self))
    }
    
    func saveKeeperInfo(_ keeperInfo: KeeperInfo) throws {
        try saveValue(keeperInfo, for: keeperInfo.key)
    }
    
    func removeKeeperInfo() throws {
        try deleteValue(for: String(describing: T.self))
    }
}
