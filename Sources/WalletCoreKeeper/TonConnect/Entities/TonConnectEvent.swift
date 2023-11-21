//
//  TonConnectEvent.swift
//  
//
//  Created by Grigory Serebryanyy on 27.10.2023.
//

import Foundation

struct TonConnectEvent: Decodable {
    let from: String
    let message: String
}
