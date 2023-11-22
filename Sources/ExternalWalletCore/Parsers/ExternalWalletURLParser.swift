//
//  ExternalWalletURLParser.swift
//
//
//  Created by Grigory Serebryanyy on 22.11.2023.
//

import Foundation
import TonSwift

enum ExternalWalletURLParserError: Swift.Error {
    case notExternalWalletScheme
    case incorrectAction
    case incorrectParameters
    case failed
}

protocol ExternalWalletURLParser {
    func parseUrl(_ url: URL) throws -> ExternalWalletAction
}

struct ExternalWalletURLParserImplementation: ExternalWalletURLParser {
    func parseUrl(_ url: URL) throws -> ExternalWalletAction {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw ExternalWalletURLParserError.failed
        }
        guard components.scheme == "tew" else {
            throw ExternalWalletURLParserError.notExternalWalletScheme
        }
        guard components.host == "signTransfer" else {
            throw ExternalWalletURLParserError.incorrectAction
        }
        guard let publicKeyHexString = components.queryItems?.first(where: { $0.name == "pk" })?.value,
              let publicKeyData = Data(hex: publicKeyHexString),
              let bocToSign = components.queryItems?.first(where: { $0.name == "boc" })?.value else {
            throw ExternalWalletURLParserError.incorrectParameters
        }
        
        let publicKey = TonSwift.PublicKey(data: publicKeyData)
        return .signTransfer(publicKey: publicKey, boc: bocToSign)
    }
}
