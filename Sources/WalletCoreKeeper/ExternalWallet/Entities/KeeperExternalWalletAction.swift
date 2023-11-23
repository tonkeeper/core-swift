//
//  KeeperExternalWalletAction.swift
//
//
//  Created by Grigory Serebryanyy on 23.11.2023.
//

import Foundation
import TonSwift

enum KeeperExternalWalletAction {
    case importWallet(publicKey: TonSwift.PublicKey)
}
