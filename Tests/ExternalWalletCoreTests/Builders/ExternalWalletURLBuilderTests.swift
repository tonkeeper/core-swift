//
//  ExternalWalletURLBuilderTests.swift
//  
//
//  Created by Grigory Serebryanyy on 22.11.2023.
//

import XCTest
import WalletCoreCore
import TonSwift
@testable import ExternalWalletCore

final class ExternalWalletURLBuilderTests: XCTestCase {
    
    let builder = ExternalWalletURLBuilderImplementation()
    
    func test_build_export_wallet_url_success() throws {
        // GIVEN
        let publicKeyString = "7075626c69634b6579537472696e67"
        let publicKey = TonSwift.PublicKey(data: Data(hex: publicKeyString)!)
        let url = URL(string: "tk://export?pk=\(publicKeyString)")!
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(publicKey)))
        
        //WHEN
        let builtUrl = try builder.buildWalletExportUrl(wallet: wallet)
        
        // THEN
        XCTAssertEqual(builtUrl, url)
    }
    
    func test_build_export_wallet_url_throw_error_if_wallet_is_not_regular() throws {
        // GIVEN
        let publicKeyString = "7075626c69634b6579537472696e67"
        let publicKey = TonSwift.PublicKey(data: Data(hex: publicKeyString)!)
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .External(publicKey)))
        
        // WHEN
        var error: Error?
        XCTAssertThrowsError(try builder.buildWalletExportUrl(wallet: wallet)) {
            error = $0
        }
        // THEN
        XCTAssertEqual(error as? ExternalWalletURLBuilderError, ExternalWalletURLBuilderError.notRegularWallet)
    }
    
    func test_build_transaction_signed_url_success() throws {
        // GIVEN
        let publicKeyString = "7075626c69634b6579537472696e67"
        let publicKey = TonSwift.PublicKey(data: Data(hex: publicKeyString)!)
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(publicKey)))
        let boc = "signedBoc"
        let url = URL(string: "tk://signedTransfer?pk=\(publicKeyString)&boc=\(boc)")!
        
        //WHEN
        let builtUrl = try builder.buildTransactionSignedUrl(wallet: wallet, signedBoc: boc)
        
        // THEN
        XCTAssertEqual(builtUrl, url)
    }
}
