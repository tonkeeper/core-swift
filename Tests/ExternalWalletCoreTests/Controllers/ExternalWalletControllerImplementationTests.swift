//
//  ExternalWalletControllerImplementationTests.swift
//  
//
//  Created by Grigory Serebryanyy on 22.11.2023.
//

import XCTest
import TonSwift
import WalletCoreCore
@testable import ExternalWalletCore

final class ExternalWalletControllerImplementationTests: XCTestCase {
    
    var mockWalletProvider = MockWalletProvider()
    var mockExternalWalletURLParser = MockExternalWalletURLParser()
    var mockExternalWalletURLBuilder = MockExternalWalletURLBuilder()
    
    lazy var controller = ExternalWalletControllerImplementation(walletProvider: mockWalletProvider,
                                                                 urlParser: mockExternalWalletURLParser,
                                                                 urlBuilder: mockExternalWalletURLBuilder)
    
    func test_incorrect_url_process_throw_incorrect_url_error() throws {
        // GIVEN
        let url = URL(string: "https://tonkeeper.com")!
        mockExternalWalletURLParser._error = .notExternalWalletScheme
        
        // WHEN
        var error: Error?
        XCTAssertThrowsError(try controller.processUrl(url)) { error = $0 }
        
        // THEN
        XCTAssertEqual(error as? ExternalWalletControllerError, ExternalWalletControllerError.incorrectUrl)
    }
    
    func test_url_process_with_no_wallets_throw_no_wallet_error() throws {
        // GIVEN
        let url = URL(string: "https://tonkeeper.com")!
        let publicKeyString = "7075626c69634b6579537472696e67"
        mockExternalWalletURLParser._action = .signTransfer(publicKey: .init(data: .init(hex: publicKeyString)!), boc: "")
        
        // WHEN
        var error: Error?
        XCTAssertThrowsError(try controller.processUrl(url)) { error = $0 }
        
        // THEN
        XCTAssertEqual(error as? ExternalWalletControllerError, ExternalWalletControllerError.noWalletToSignTransfer)
    }
    
    func test_url_process_success_if_has_regular_wallet_and_correct_url_and_not_processing_other_transfer() throws {
        //GIVEN
        let url = URL(string: "https://tonkeeper.com")!
        let publicKey = TonSwift.PublicKey(data: Data(hex: "7075626c69634b6579537472696e67")!)
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(publicKey)))
        mockWalletProvider._wallets = [wallet]
        mockExternalWalletURLParser._action = .signTransfer(publicKey: publicKey, boc: "boc")
        
        // WHEN
        let action = try controller.processUrl(url)
        
        // THEN
        switch action {
        case let .signTransfer(actionWallet, actionBoc):
            XCTAssertEqual(actionWallet, wallet)
            XCTAssertEqual(actionBoc, "boc")
        }
    }
    
    func test_url_process_fail_if_processing_other_transfer() throws {
        //GIVEN
        let url = URL(string: "https://tonkeeper.com")!
        let publicKey = TonSwift.PublicKey(data: Data(hex: "7075626c69634b6579537472696e67")!)
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(publicKey)))
        mockWalletProvider._wallets = [wallet]
        mockExternalWalletURLParser._action = .signTransfer(publicKey: publicKey, boc: "boc")
        
        // WHEN
        var error: Error?
        XCTAssertNoThrow(try controller.processUrl(url))
        XCTAssertThrowsError(try controller.processUrl(url)) { error = $0 }
        
        // THEN
        XCTAssertEqual(error as? ExternalWalletControllerError, ExternalWalletControllerError.alreadyProcessingTransfer)
    }
    
    func test_url_process_success_after_reset() throws {
        //GIVEN
        let url = URL(string: "https://tonkeeper.com")!
        let publicKey = TonSwift.PublicKey(data: Data(hex: "7075626c69634b6579537472696e67")!)
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(publicKey)))
        mockWalletProvider._wallets = [wallet]
        mockExternalWalletURLParser._action = .signTransfer(publicKey: publicKey, boc: "boc")
        
        // WHEN
        XCTAssertNoThrow(try controller.processUrl(url))
        controller.reset()
        
        // THEN
        XCTAssertNoThrow(try controller.processUrl(url))
    }
    
    func test_export_wallet_success() throws {
        // GIVEN
        let url = URL(string: "https://tonkeeper.com")!
        mockExternalWalletURLBuilder._url = url
        let publicKey = TonSwift.PublicKey(data: Data(hex: "7075626c69634b6579537472696e67")!)
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(publicKey)))
        
        // WHEN
        let controllerUrl = try controller.exportWallet(wallet)
        
        // THEN
        XCTAssertEqual(controllerUrl, url)
    }
    
    func test_export_wallet_failed() throws {
        // GIVEN
        mockExternalWalletURLBuilder._error = .failedToBuildUrl
        let publicKey = TonSwift.PublicKey(data: Data(hex: "7075626c69634b6579537472696e67")!)
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(publicKey)))
        
        // WHEN
        var error: Error?
        XCTAssertThrowsError(try controller.exportWallet(wallet)) { error = $0 }
        
        // THEN
        XCTAssertEqual(error as? ExternalWalletControllerError, ExternalWalletControllerError.failedToBuildWalletExportURL)
    }
}

