//
//  MockExternalWalletURLBuilder.swift
//
//
//  Created by Grigory Serebryanyy on 22.11.2023.
//

import Foundation
import WalletCoreCore
@testable import ExternalWalletCore

struct MockExternalWalletURLBuilder: ExternalWalletURLBuilder {
    enum Error: Swift.Error {
        case incorrect
    }
    
    var _url: URL?
    var _error: ExternalWalletURLBuilderError?
    
    func buildWalletExportUrl(wallet: Wallet) throws -> URL {
        if let _url = _url {
            return _url
        }
        if let _error = _error {
            throw _error
        }
        throw Error.incorrect
    }
    
    func buildTransactionSignedUrl(wallet: Wallet, signedBoc: String) throws -> URL {
        if let _url = _url {
            return _url
        }
        if let _error = _error {
            throw _error
        }
        throw Error.incorrect
    }
}
