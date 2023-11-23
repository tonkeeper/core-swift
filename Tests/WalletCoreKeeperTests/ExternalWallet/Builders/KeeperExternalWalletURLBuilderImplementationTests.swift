//
//  KeeperExternalWalletURLBuilderImplementationTests.swift
//  
//
//  Created by Grigory Serebryanyy on 23.11.2023.
//

import XCTest
import TonSwift
import WalletCoreCore
@testable import WalletCoreKeeper

final class KeeperExternalWalletURLBuilderImplementationTests: XCTestCase {
  
  let keeperExternalWalletURLBuilder = KeeperExternalWalletURLBuilderImplementation()

  func test_build_wallet_import_url_success() throws {
    // GIVEN
    let url = URL(string: "tew://")
    
    // WHEN
    let builtUrl = try keeperExternalWalletURLBuilder.buildWalletImportUrl()
    
    // THEN
    XCTAssertEqual(builtUrl, url)
  }
  
  func test_build_sign_external_wallet_transfer_url_success() throws {
    // GIVEN
    let publicKeyString = "7075626c69634b6579537472696e67"
    let publicKey = TonSwift.PublicKey(data: Data(hex: publicKeyString)!)
    let wallet = Wallet(identity: .init(network: .mainnet, kind: .External(publicKey)))
    let boc = "bocToSign"
    let url = URL(string: "tew://signTransfer?pk=\(publicKeyString)&boc=\(boc)")!
    
    // WHEN
    let builtUrl = try keeperExternalWalletURLBuilder.buildSignExternalWalletTransfer(
      wallet: wallet,
      boc: boc
    )
    
    // THEN
    XCTAssertEqual(builtUrl, url)
  }
  
  func test_build_sign_external_wallet_transfer_url_throws_error_if_not_external_wallet() throws {
    // GIVEN
    let publicKeyString = "7075626c69634b6579537472696e67"
    let publicKey = TonSwift.PublicKey(data: Data(hex: publicKeyString)!)
    let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(publicKey)))
    let boc = "bocToSign"
    
    // WHEN
    var error: Error?
    XCTAssertThrowsError(try keeperExternalWalletURLBuilder
      .buildSignExternalWalletTransfer(
        wallet: wallet,
        boc: boc)) {
        error = $0
    }
    // THEN
    XCTAssertEqual(error as? KeeperExternalWalletURLBuilderError, KeeperExternalWalletURLBuilderError.notExternalWallet)
  }
}
