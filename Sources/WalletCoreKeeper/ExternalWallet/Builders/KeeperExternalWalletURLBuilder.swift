//
//  KeeperExternalWalletURLBuilder.swift
//
//
//  Created by Grigory Serebryanyy on 23.11.2023.
//

import Foundation
import WalletCoreCore
import TonSwift

public enum KeeperExternalWalletURLBuilderError: Swift.Error {
    case failedToBuildImportUrl
    case failedToBuildSignExternalWalletTransfer
    case notExternalWallet
}

public protocol KeeperExternalWalletURLBuilder {
    func buildWalletImportUrl() throws -> URL
    func buildSignExternalWalletTransfer(wallet: Wallet, boc: String) throws -> URL
}

struct KeeperExternalWalletURLBuilderImplementation: KeeperExternalWalletURLBuilder {
    func buildWalletImportUrl() throws -> URL {
        guard let url = URL(string: "tew://") else { throw KeeperExternalWalletURLBuilderError.failedToBuildImportUrl }
        return url
    }
    
    func buildSignExternalWalletTransfer(wallet: Wallet, boc: String) throws -> URL {
        guard wallet.isExternal else { throw KeeperExternalWalletURLBuilderError.notExternalWallet }
        let publicKey: TonSwift.PublicKey
        do {
            publicKey = try wallet.publicKey
        } catch {
            throw KeeperExternalWalletURLBuilderError.failedToBuildSignExternalWalletTransfer
        }
        let publicKeyHex = publicKey.data.hexString()
        var components = URLComponents()
        components.scheme = "tew"
        components.host = "signTransfer"
        components.queryItems = [
            URLQueryItem(name: "pk", value: publicKeyHex),
            URLQueryItem(name: "boc", value: boc)
        ]
        guard let url = components.url else { throw KeeperExternalWalletURLBuilderError.failedToBuildSignExternalWalletTransfer }
        return url
    }
}
