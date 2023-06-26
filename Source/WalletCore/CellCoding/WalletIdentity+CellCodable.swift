//
//  WalletIdentity+CellCodable.swift
//  
//
//  Created by Grigory on 26.6.23..
//

import Foundation
import TonSwift

extension WalletIdentity: CellCodable {
    public func storeTo(builder: Builder) throws {
        try network.storeTo(builder: builder)
        try kind.storeTo(builder: builder)
    }
    
    public static func loadFrom(slice: Slice) throws -> WalletIdentity {
        return try slice.tryLoad { s in
            let network: Network = try s.loadType()
            let kind: WalletKind = try s.loadType()
            return WalletIdentity(network: network, kind: kind)
        }
    }
}

