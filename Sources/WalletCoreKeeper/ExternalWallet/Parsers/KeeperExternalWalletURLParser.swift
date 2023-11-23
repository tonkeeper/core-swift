//
//  KeeperExternalWalletURLParser.swift
//
//
//  Created by Grigory Serebryanyy on 23.11.2023.
//

import Foundation
import TonSwift

enum KeeperExternalWalletURLParserError: Swift.Error {
    case incorrectScheme
    case incorrectAction
    case incorrectParameters
    case failed
}

protocol KeeperExternalWalletURLParser {
    func parseUrl(_ url: URL) throws -> KeeperExternalWalletAction
}

struct KeeperExternalWalletURLParserImplementation: KeeperExternalWalletURLParser {
    func parseUrl(_ url: URL) throws -> KeeperExternalWalletAction {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw KeeperExternalWalletURLParserError.failed
        }
        guard components.scheme == "tk" else {
            throw KeeperExternalWalletURLParserError.failed
        }
        guard components.host == "import" else {
            throw KeeperExternalWalletURLParserError.incorrectAction
        }
        guard let publicKeyHexString = components.queryItems?.first(where: { $0.name == "pk" })?.value,
              let publicKeyData = Data(hex: publicKeyHexString) else {
            throw KeeperExternalWalletURLParserError.incorrectParameters
        }
        
        let publicKey = TonSwift.PublicKey(data: publicKeyData)
        return .importWallet(publicKey: publicKey)
    }
}
