//
//  TonConnectItemReply.swift
//  
//
//  Created by Grigory Serebryanyy on 26.10.2023.
//

import Foundation

protocol TonConnectItemReply: Encodable {}
struct TonConnectItemReplyWrapper: Encodable {
    let value: TonConnectItemReply
    
    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
