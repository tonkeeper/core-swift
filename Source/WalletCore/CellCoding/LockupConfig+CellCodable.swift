//
//  LockupConfig+CellCodable.swift
//  
//
//  Created by Grigory on 26.6.23..
//

import Foundation
import TonSwift


extension LockupConfig: CellCodable {
    func storeTo(builder: Builder) throws {
        // TBD: Store config
    }
    static func loadFrom(slice: Slice) throws -> LockupConfig {
        // TBD: Load config
        return LockupConfig()
    }
}
