//
//  ExternalWalletURLParserImplementationTests.swift
//  
//
//  Created by Grigory Serebryanyy on 22.11.2023.
//

import XCTest
import TonSwift
@testable import ExternalWalletCore

final class ExternalWalletURLParserImplementationTests: XCTestCase {
    
    let parser = ExternalWalletURLParserImplementation()
    
    func test_parse_sign_transfer_action_success() throws {
        // GIVEN
        let publicKeyString = "7075626c69634b6579537472696e67"
        let bocString = "Ym9jU3RyaW5n"
        let url = URL(string: "tew://signTransfer?pk=\(publicKeyString)&boc=\(bocString)")!
        
        // WHEN
        let action = try parser.parseUrl(url)
        
        // THEN
        switch action {
        case .signTransfer(let publicKey, let boc):
            XCTAssertEqual(publicKey.data, Data(hex: publicKeyString))
            XCTAssertEqual(boc, bocString)
        }
    }
    
    func test_parse_fail_if_wrong_schema() throws {
        // GIVEN
        let url = URL(string: "nottew://signTransfer")!
        
        // WHEN
        var error: Error?
        XCTAssertThrowsError(try parser.parseUrl(url)) {
            error = $0
        }
        // THEN
        XCTAssertEqual(error as? ExternalWalletURLParserError, ExternalWalletURLParserError.notExternalWalletScheme)
    }
    
    func test_parse_fail_if_incorrect_action() throws {
        // GIVEN
        let url = URL(string: "tew://doSomething")!
        
        // WHEN
        var error: Error?
        XCTAssertThrowsError(try parser.parseUrl(url)) {
            error = $0
        }
        // THEN
        XCTAssertEqual(error as? ExternalWalletURLParserError, ExternalWalletURLParserError.incorrectAction)
    }
    
    func test_parse_sign_transfer_action_fails_if_no_public_key() throws {
        // GIVEN
        let bocString = "Ym9jU3RyaW5n"
        let url = URL(string: "tew://signTransfer?boc=\(bocString)")!
        
        // WHEN
        var error: Error?
        XCTAssertThrowsError(try parser.parseUrl(url)) {
            error = $0
        }
        // THEN
        XCTAssertEqual(error as? ExternalWalletURLParserError, ExternalWalletURLParserError.incorrectParameters)
    }
    
    func test_parse_sign_transfer_action_fails_if_public_key_not_hex_string() throws {
        // GIVEN
        let publicKeyString = "noHexString"
        let bocString = "Ym9jU3RyaW5n"
        let url = URL(string: "tew://signTransfer?pk=\(publicKeyString)&boc=\(bocString)")!
        
        // WHEN
        var error: Error?
        XCTAssertThrowsError(try parser.parseUrl(url)) {
            error = $0
        }
        // THEN
        XCTAssertEqual(error as? ExternalWalletURLParserError, ExternalWalletURLParserError.incorrectParameters)
    }
    
    func test_parse_sign_transfer_action_fails_if_no_boc() throws {
        // GIVEN
        let publicKeyString = "7075626c69634b6579537472696e67"
        let url = URL(string: "tew://signTransfer?pk=\(publicKeyString)")!
        
        // WHEN
        var error: Error?
        XCTAssertThrowsError(try parser.parseUrl(url)) {
            error = $0
        }
        // THEN
        XCTAssertEqual(error as? ExternalWalletURLParserError, ExternalWalletURLParserError.incorrectParameters)
    }
}
