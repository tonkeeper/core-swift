//
//  TransferSignControllerImplementationTests.swift
//  
//
//  Created by Grigory Serebryanyy on 22.11.2023.
//

import XCTest
import WalletCoreCore
import TonSwift
import BigInt
@testable import ExternalWalletCore

final class TransferSignControllerImplementationTests: XCTestCase {
    
    var mockWalletProvider = MockWalletProvider()
    lazy var controller = TransferSignControllerImplementation(walletProvider: mockWalletProvider)
    
    override func setUp() {
        mockWalletProvider.reset()
    }
    
    func test_sign_boc_success() async throws {
        // GIVEN
        let publicKeyHexString = "1d0ae0c4cb9946afdc7451dbdb189cda43a01577961fa0d6d0be6b94f8752287"
        let privateKeyHexString = "d0b8cb2b0e3fe8b479b5937865223efb888967a516b09a6a58f54474865537c11d0ae0c4cb9946afdc7451dbdb189cda43a01577961fa0d6d0be6b94f8752287"
        let publicKey = TonSwift.PublicKey(data: Data(hex: publicKeyHexString)!)
        let privateKey = TonSwift.PrivateKey(data: Data(hex: privateKeyHexString)!)
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(publicKey)), contractVersion: .v4R2)
        mockWalletProvider._wallets = [wallet]
        mockWalletProvider._privateKeys[wallet] = privateKey

        let unsignedBoc = "te6cckECAgEAAKcAAeGIAf++WZehiZEwQOSSja4rqhpfNzphsc/EZvOAtAQ9mSrIAYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYFNTRi7KvIISAAABlgAHAEAYmIAO87mQKicbKgHIk4pSPP4k5xhHqutqYgAB7USnesDnCcIUAAAAAAAAAAAAAAAAABHwCdC"
        let signedBoc = "te6cckECAgEAAKcAAeGIAf++WZehiZEwQOSSja4rqhpfNzphsc/EZvOAtAQ9mSrIACny9Q+FzsNSDcHtNDymcdN5WBMviUx/BwCa/Lv/EJY3Osm23V9fmX94NIcGE44iYjVLLu1UGtnTHZqnMjjXmHFNTRi7KvIISAAABlgAHAEAYmIAO87mQKicbKgHIk4pSPP4k5xhHqutqYgAB7USnesDnCcIUAAAAAAAAAAAAAAAAAB5S+ks"
        
        // WHEN
        let controllerBoc = try controller.signTransfer(wallet: wallet, boc: unsignedBoc)
        
        // THEN
        XCTAssertEqual(controllerBoc, signedBoc)
    }
    
    func test_sign_boc_throws_error_if_no_private_key_for_wallet() async throws {
        // GIVEN
        let publicKeyHexString = "1d0ae0c4cb9946afdc7451dbdb189cda43a01577961fa0d6d0be6b94f8752287"
        let publicKey = TonSwift.PublicKey(data: Data(hex: publicKeyHexString)!)
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(publicKey)), contractVersion: .v4R2)
        mockWalletProvider._wallets = [wallet]

        // WHEN
        var error: Error?
        XCTAssertThrowsError(try controller.signTransfer(wallet: wallet, boc: "boc")) { error = $0 }
        
        // THEN
        XCTAssertEqual(error as? TransferSignControllerError, TransferSignControllerError.failedToGetWalletPrivateKey)
    }
    
    func test_sign_boc_throws_error_if_incorrect_boc() async throws {
        // GIVEN
        let publicKeyHexString = "1d0ae0c4cb9946afdc7451dbdb189cda43a01577961fa0d6d0be6b94f8752287"
        let privateKeyHexString = "d0b8cb2b0e3fe8b479b5937865223efb888967a516b09a6a58f54474865537c11d0ae0c4cb9946afdc7451dbdb189cda43a01577961fa0d6d0be6b94f8752287"
        let publicKey = TonSwift.PublicKey(data: Data(hex: publicKeyHexString)!)
        let privateKey = TonSwift.PrivateKey(data: Data(hex: privateKeyHexString)!)
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(publicKey)), contractVersion: .v4R2)
        mockWalletProvider._wallets = [wallet]
        mockWalletProvider._privateKeys[wallet] = privateKey

        // WHEN
        var error: Error?
        XCTAssertThrowsError(try controller.signTransfer(wallet: wallet, boc: "boc")) { error = $0 }
        
        // THEN
        XCTAssertEqual(error as? TransferSignControllerError, TransferSignControllerError.failedToSignTransfer)
    }
}
