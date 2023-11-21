//
//  TonConnectError.swift
//  
//
//  Created by Grigory Serebryanyy on 27.10.2023.
//

import Foundation

struct TonConnectError: Swift.Error, Decodable {
    let statusCode: Int
    let message: String
}
