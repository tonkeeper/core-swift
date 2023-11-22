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
    
    let builder = ExternalWalletURLBuilder()
    
    func test_build_export_wallet_url_success() throws {
        // GIVEN
        let publicKeyString = "7075626c69634b6579537472696e67"
        let publicKey = TonSwift.PublicKey(data: Data(hex: publicKeyString)!)
        let url = URL(string: "tk://export?pk=\(publicKeyString)")!
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(publicKey)))
        
        //WHEN
        let builtUrl = try builder.buildExportUrl(wallet: wallet)
        
        // THEN
        XCTAssertEqual(builtUrl, url)
    }
    
    func test_build_export_wallet_url_throw_error_if_wallet_is_not_regular() throws {
        // GIVEN
        let publicKeyString = "7075626c69634b6579537472696e67"
        let publicKey = TonSwift.PublicKey(data: Data(hex: publicKeyString)!)
        let url = URL(string: "tk://export?pk=\(publicKeyString)")!
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .External(publicKey)))
        
        // WHEN
        var error: Error?
        XCTAssertThrowsError(try builder.buildExportUrl(wallet: wallet)) {
            error = $0
        }
        // THEN
        XCTAssertEqual(error as? ExternalWalletURLBuilderError, ExternalWalletURLBuilderError.notRegularWallet)
    }
}
