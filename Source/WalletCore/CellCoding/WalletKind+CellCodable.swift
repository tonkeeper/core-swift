//
//  WalletKind+CellCodable.swift
//  
//
//  Created by Grigory on 26.6.23..
//

import Foundation
import TonSwift

extension WalletKind: CellCodable {
    func storeTo(builder: Builder) throws {
        switch self {
        case let .Regular(publicKey):
            try builder.store(uint: 0, bits: 2)
            try publicKey.storeTo(builder: builder)
        case let .Lockup(publicKey, lockupConfig):
            try builder.store(uint: 1, bits: 2)
            try publicKey.storeTo(builder: builder)
            try lockupConfig.storeTo(builder: builder)
        case let .Watchonly(resolvableAddress):
            try builder.store(uint: 2, bits: 2)
            try resolvableAddress.storeTo(builder: builder)
        }
    }
    
    static func loadFrom(slice: Slice) throws -> WalletKind {
        return try slice.tryLoad { s in
            let type = try s.loadUint(bits: 2)
            switch type {
            case 0:
                let publicKey: TonSwift.PublicKey = try s.loadType()
                return .Regular(publicKey)
            case 1:
                let publicKey: TonSwift.PublicKey = try s.loadType()
                let lockupConfig: LockupConfig = try s.loadType()
                return .Lockup(publicKey, lockupConfig)
            case 2:
                let resolvableAddress: ResolvableAddress = try s.loadType()
                return .Watchonly(resolvableAddress)
            default:
                throw TonError.custom("Invalid WalletKind type");
            }
        }
    }
}
