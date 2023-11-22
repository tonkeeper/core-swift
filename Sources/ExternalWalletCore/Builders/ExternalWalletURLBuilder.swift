//
//  ExternalWalletURLBuilder.swift
//
//
//  Created by Grigory Serebryanyy on 22.11.2023.
//

import Foundation
import WalletCoreCore
import TonSwift

enum ExternalWalletURLBuilderError: Swift.Error {
    case notRegularWallet
    case failedToGetWalletPublicKey
    case failedToBuildUrl
}

protocol ExternalWalletURLBuilder {
    func buildWalletExportUrl(wallet: Wallet) throws -> URL
}

struct ExternalWalletURLBuilderImplementation: ExternalWalletURLBuilder {
    func buildWalletExportUrl(wallet: Wallet) throws -> URL {
        guard wallet.isRegular else { throw ExternalWalletURLBuilderError.notRegularWallet }
        let publicKey: TonSwift.PublicKey
        do {
            publicKey = try wallet.publicKey
        } catch {
            throw ExternalWalletURLBuilderError.failedToGetWalletPublicKey
        }
        let publicKeyHex = publicKey.data.hexString()
        var components = URLComponents()
        components.scheme = "tk"
        components.host = "export"
        components.queryItems = [URLQueryItem(name: "pk", value: publicKeyHex)]
        guard let url = components.url else { throw ExternalWalletURLBuilderError.failedToBuildUrl }
        return url
    }
}
