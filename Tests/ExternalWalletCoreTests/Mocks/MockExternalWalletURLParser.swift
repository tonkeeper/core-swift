//
//  MockExternalWalletURLParser.swift
//
//
//  Created by Grigory Serebryanyy on 22.11.2023.
//

import Foundation
@testable import ExternalWalletCore

struct MockExternalWalletURLParser: ExternalWalletURLParser {
    
    enum Error: Swift.Error {
        case incorrect
    }
    
    var _action: ExternalWalletAction?
    var _error: ExternalWalletURLParserError?
    
    func parseUrl(_ url: URL) throws -> ExternalWalletCore.ExternalWalletAction {
        if let _action = _action {
            return _action
        }
        if let _error = _error {
            throw _error
        }
        throw Error.incorrect
    }
}
