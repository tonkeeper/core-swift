//
//  ExternalWalletURLBuilder.swift
//
//
//  Created by Grigory Serebryanyy on 22.11.2023.
//

import Foundation
import WalletCoreCore
import TonSwift

public enum ExternalWalletURLBuilderError: Swift.Error {
    case notRegularWallet
    case failedToGetWalletPublicKey
    case failedToBuildUrl
}

public protocol ExternalWalletURLBuilder {
    func buildWalletExportUrl(wallet: Wallet) throws -> URL
    func buildTransactionSignedUrl(wallet: Wallet, signedBoc: String) throws -> URL
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
        components.host = "import"
        components.queryItems = [URLQueryItem(name: "pk", value: publicKeyHex)]
        guard let url = components.url else { throw ExternalWalletURLBuilderError.failedToBuildUrl }
        return url
    }
    
    func buildTransactionSignedUrl(wallet: Wallet, signedBoc: String) throws -> URL {
        let publicKey: TonSwift.PublicKey
        do {
            publicKey = try wallet.publicKey
        } catch {
            throw ExternalWalletURLBuilderError.failedToGetWalletPublicKey
        }
        let publicKeyHex = publicKey.data.hexString()
        var components = URLComponents()
        components.scheme = "tk"
        components.host = "signedTransfer"
        components.queryItems = [
            URLQueryItem(name: "pk", value: publicKeyHex),
            URLQueryItem(name: "boc", value: signedBoc)
        ]
        guard let url = components.url else { throw ExternalWalletURLBuilderError.failedToBuildUrl }
        return url
    }
}
