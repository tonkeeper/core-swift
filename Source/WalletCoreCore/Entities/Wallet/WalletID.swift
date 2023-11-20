//
//  WalletID.swift
//  
//
//  Created by Grigory Serebryanyy on 17.11.2023.
//

import Foundation
import TonSwift

public struct WalletID: Hashable, Codable {
    public let hash: Data
    public var string: String {
        hash.hexString()
    }
}
