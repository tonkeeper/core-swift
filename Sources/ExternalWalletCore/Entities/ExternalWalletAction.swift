//
//  File.swift
//  
//
//  Created by Grigory Serebryanyy on 22.11.2023.
//

import Foundation
import TonSwift

enum ExternalWalletAction {
    case signTransfer(publicKey: TonSwift.PublicKey, boc: String)
}
