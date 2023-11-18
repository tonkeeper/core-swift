//
//  WalletID.swift
//  
//
//  Created by Grigory Serebryanyy on 17.11.2023.
//

import Foundation
import TonSwift

struct WalletID: Hashable, Codable {
    let hash: Data
    var string: String {
        hash.hexString()
    }
}
