//
//  LockupConfig.swift
//
//
//  Created by Grigory Serebryanyy on 17.11.2023.
//

import Foundation
import TonSwift

struct LockupConfig: Equatable {
    // TBD: lockup-1.0 config
}

extension LockupConfig: CellCodable {
    func storeTo(builder: Builder) throws {
        // TBD: Store config
    }
    static func loadFrom(slice: Slice) throws -> LockupConfig {
        // TBD: Load config
        return LockupConfig()
    }
}
