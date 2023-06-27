//
//  KeeperControllerTests.swift
//  
//
//  Created by Grigory on 27.6.23..
//

import XCTest
import TonSwift
@testable import WalletCore

final class KeeperControllerTests: XCTestCase {
    let mockLocalRepository = MockLocalRepository()
    let mockKeychain = MockKeychain()
    
    lazy var controller: KeeperController = {
        let keeperService = KeeperInfoServiceImplementation(localRepository: mockLocalRepository)
        let keychainManager = KeychainManager(keychain: mockKeychain)
        let controller = KeeperController(keeperService: keeperService,
                                          keychainManager: keychainManager)
        return controller
    }()
    
    override func setUp() {
        mockKeychain.reset()
        mockLocalRepository.keeperInfo = nil
    }
    
    func testIfNoKeeperInfoHasWalletsFalse() throws {
        XCTAssertFalse(controller.hasWallets)
    }
    
    func testIfOnlyWatchonlyWalletHasWalletsTrue() throws {
        let address = TonSwift.Address.mock(workchain: 0, seed: "testResolvableAddressResolvedCoding")
        let wallet = Wallet(identity: WalletIdentity(network: .testnet, kind: .Watchonly(.Resolved(address))),
                            notificationSettings: NotificationSettings(),
                            backupSettings: WalletBackupSettings(enabled: true, revision: 1, voucher: nil))
        mockLocalRepository.keeperInfo = .init(
            wallets: [wallet],
            currentWallet: wallet,
            securitySettings: SecuritySettings(),
            assetsPolicy: AssetsPolicy(policies: [:], ordered: []),
            appCollection: .init(connected: [:], recent: [], pinned: []))
        
        XCTAssertTrue(controller.hasWallets)
    }
    
    func testIfOnlyRegularWalletWithoutSavedMnemonicHasWalletsReturnsFalse() throws {
        let publicKey = TonSwift.PublicKey(data: Data(hex: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!)
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(publicKey)),
                            notificationSettings: NotificationSettings(),
                            backupSettings: WalletBackupSettings(enabled: true, revision: 1, voucher: nil))
        mockLocalRepository.keeperInfo = .init(
            wallets: [wallet],
            currentWallet: wallet,
            securitySettings: SecuritySettings(),
            assetsPolicy: AssetsPolicy(policies: [:], ordered: []),
            appCollection: .init(connected: [:], recent: [], pinned: []))
        
        XCTAssertFalse(controller.hasWallets)
    }
    
    func testIfOnlyRegularWalletWitSavedMnemonicHasWalletsReturnsTrue() throws {
        let publicKey = TonSwift.PublicKey(data: Data(hex: "5754865e86d0ade1199301bbb0319a25ed6b129c4b0a57f28f62449b3df9c522")!)
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(publicKey)),
                            notificationSettings: NotificationSettings(),
                            backupSettings: WalletBackupSettings(enabled: true, revision: 1, voucher: nil))
        mockLocalRepository.keeperInfo = .init(
            wallets: [wallet],
            currentWallet: wallet,
            securitySettings: SecuritySettings(),
            assetsPolicy: AssetsPolicy(policies: [:], ordered: []),
            appCollection: .init(connected: [:], recent: [], pinned: []))
        
        let mnemonic = Mnemonic.mnemonicNew(wordsCount: 5)
        
        mockKeychain.getResult = .success(try JSONEncoder().encode(mnemonic))
        
        XCTAssertTrue(controller.hasWallets)
    }
    
    func testIfAddWalletWithoutKeeperInfoNewKeeperInfoCreated() throws {
        mockKeychain.resultCode = .success
        mockKeychain.getResult = .failed(.errSecItemNotFound)
        
        let mnemonic = Mnemonic.mnemonicNew(wordsCount: 5)
        let keyPair = try Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonic)
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(keyPair.publicKey)),
                            notificationSettings: NotificationSettings(),
                            backupSettings: WalletBackupSettings(enabled: true, revision: 1, voucher: nil))
        
        XCTAssertNil(mockLocalRepository.keeperInfo)
        
        try controller.addWallet(with: mnemonic)
        
        XCTAssertEqual(mockLocalRepository.keeperInfo?.wallets.count, 1)
        XCTAssertEqual(try mockLocalRepository.keeperInfo?.wallets.first?.identity.id(), try wallet.identity.id())
        XCTAssertEqual(mockKeychain.query.data, try JSONEncoder().encode(mnemonic))
    }
    
    func testIfAddWalletToExistedWallet() throws {
        mockKeychain.resultCode = .success
        mockKeychain.getResult = .failed(.errSecItemNotFound)
        
        let addedMnemonic = Mnemonic.mnemonicNew(wordsCount: 5)
        let addedKeyPair = try Mnemonic.mnemonicToPrivateKey(mnemonicArray: addedMnemonic)
        let addedWallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(addedKeyPair.publicKey)),
                                 notificationSettings: NotificationSettings(),
                                 backupSettings: WalletBackupSettings(enabled: true, revision: 1, voucher: nil))
        
        let keeperInfo = KeeperInfo(
            wallets: [addedWallet],
            currentWallet: addedWallet,
            securitySettings: SecuritySettings(),
            assetsPolicy: AssetsPolicy(policies: [:], ordered: []),
            appCollection: .init(connected: [:], recent: [], pinned: []))
        
        mockLocalRepository.keeperInfo = keeperInfo
        
        let newMnemonic = Mnemonic.mnemonicNew(wordsCount: 5)
        let newKeyPair = try Mnemonic.mnemonicToPrivateKey(mnemonicArray: newMnemonic)
        let newWallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(newKeyPair.publicKey)),
                               notificationSettings: NotificationSettings(),
                               backupSettings: WalletBackupSettings(enabled: true, revision: 1, voucher: nil))
        
        try controller.addWallet(with: newMnemonic)
        
        XCTAssertEqual(mockLocalRepository.keeperInfo?.wallets.count, 2)
        XCTAssertEqual(try mockLocalRepository.keeperInfo?.wallets.map { try $0.identity.id() },
                       try [addedWallet, newWallet].map { try $0.identity.id() })
    }
}
