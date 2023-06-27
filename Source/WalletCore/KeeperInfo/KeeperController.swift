//
//  KeeperController.swift
//  
//
//  Created by Grigory on 27.6.23..
//

import Foundation
import TonSwift

final class KeeperController {
    private let keeperService: KeeperInfoService
    private let keychainManager: KeychainManager
    
    var hasWallets: Bool {
        checkIfKeeperHasValidWallets()
    }
    
    init(keeperService: KeeperInfoService,
         keychainManager: KeychainManager) {
        self.keeperService = keeperService
        self.keychainManager = keychainManager
    }
    
    func addWallet(with mnemonic: [String]) throws {
        let keyPair = try Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonic)
        let wallet = Wallet(identity: WalletIdentity(network: .mainnet,
                                                          kind: .Regular(keyPair.publicKey)),
                            notificationSettings: .init(),
                            backupSettings: .init(enabled: true, revision: 1, voucher: nil))
        let mnemonicVault = KeychainMnemonicVault(keychainManager: keychainManager, walletID: try wallet.identity.id())
        try mnemonicVault.save(value: mnemonic, for: keyPair.publicKey)
        try updateKeeperInfo(with: wallet)
    }
}

private extension KeeperController {
    func updateKeeperInfo(with wallet: Wallet) throws {
        var keeperInfo: KeeperInfo
        do {
            keeperInfo = try keeperService.getKeeperInfo()
            keeperInfo = keeperInfo.addWallet(wallet)
        } catch {
            keeperInfo = KeeperInfo(wallets: [wallet],
                                    currentWallet: wallet,
                                    securitySettings: .init(),
                                    assetsPolicy: .init(policies: [:], ordered: []),
                                    appCollection: .init(connected: [:], recent: [], pinned: []))
        }
        
        try keeperService.saveKeeperInfo(keeperInfo)
    }
    
    func checkIfKeeperHasValidWallets() -> Bool {
        do {
            let keeperInfo = try keeperService.getKeeperInfo()
            guard !keeperInfo.wallets.isEmpty else { return false }
            let validWallets = keeperInfo.wallets.filter { wallet in
                // TBD: check Lockup walletkind
                guard case .Regular(let publicKey) = wallet.identity.kind else {
                    return true
                }
                return checkIfMnenomicExists(publicKey: publicKey, wallet: wallet)
            }
            return !validWallets.isEmpty
        } catch {
            return false
        }
    }
    
    func checkIfMnenomicExists(publicKey: TonSwift.PublicKey, wallet: Wallet) -> Bool {
        do {
            let mnemonicVault = KeychainMnemonicVault(keychainManager: keychainManager, walletID: try wallet.identity.id())
            let mnemonic = try mnemonicVault.loadValue(key: publicKey)
            return Mnemonic.mnemonicValidate(mnemonicArray: mnemonic)
        } catch {
            return false
        }
    }
}
