//
//  WalletIdentity.swift
//  
//
//  Created by Grigory Serebryanyy on 17.11.2023.
//

import Foundation
import TonSwift

public struct WalletIdentity: Equatable {
    public let network: Network
    public let kind: WalletKind
    
    public func id() throws -> WalletID {
        let builder = Builder()
        try builder.store(self)
        return WalletID(hash: try builder.endCell().representationHash())
    }
    
    public static func == (lhs: WalletIdentity, rhs: WalletIdentity) -> Bool {
        (try? lhs.id() == rhs.id()) ?? false
    }
}

extension WalletIdentity: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let identityBinaryString = try container.decode(String.self)
        let identityBitstring = try Bitstring(binaryString: identityBinaryString)
        self = try Slice(bits: identityBitstring).loadType()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let identityBinaryString = try Builder().store(self).bitstring().toBinary()
        try container.encode(identityBinaryString)
    }
}

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