//
//  TCTonAddressItemReply.swift
//  
//
//  Created by Grigory Serebryanyy on 19.10.2023.
//

import Foundation
import TonSwift

struct TCTonAddressItemReply {
    let name = "ton_addr"
    let address: TonSwift.Address
    let network: Network
    let publicKey: TonSwift.PublicKey
    let walletStateInit: TonSwift.StateInit
}

extension TCTonAddressItemReply: TonConnectItemReply, Encodable {
    enum CodingKeys: String, CodingKey {
        case name
        case address
        case network
        case publicKey
        case walletStateInit
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(address.toRaw(), forKey: .address)
        try container.encode("\(network.rawValue)", forKey: .network)
        try container.encode(publicKey.hexString, forKey: .publicKey)
        
        let builder = Builder()
        try walletStateInit.storeTo(builder: builder)
        try container.encode(builder.endCell().toBoc().hexString(), forKey: .walletStateInit)
    }
}
