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
    private let mnemonicVault: KeychainMnemonicVault
    
    var hasWallets: Bool {
        checkIfKeeperHasValidWallets()
    }
    
    init(keeperService: KeeperInfoService,
         mnemonicVault: KeychainMnemonicVault) {
        self.keeperService = keeperService
        self.mnemonicVault = mnemonicVault
    }
    
    func addWallet(with mnemonic: [String]) throws {
        let keyPair = try Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonic)
        try mnemonicVault.save(value: mnemonic, for: keyPair.publicKey)
        let wallet = Wallet(identity: WalletIdentity(network: .mainnet,
                                                          kind: .Regular(keyPair.publicKey)),
                            notificationSettings: .init(),
                            backupSettings: .init(enabled: true, revision: 1, voucher: nil))
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
            let isWalletsValid = keeperInfo.wallets.map {
                guard case .Regular(let publicKey) = $0.identity.kind else {
                    return true
                }
                // TBD: check Lockup walletkind
                return checkIfMnenomicExists(publicKey: publicKey)
            }.allSatisfy { $0 }
            return isWalletsValid
        } catch {
            return false
        }
    }
    
    func checkIfMnenomicExists(publicKey: TonSwift.PublicKey) -> Bool {
        do {
            let mnemonic = try mnemonicVault.loadValue(key: publicKey)
            return Mnemonic.mnemonicValidate(mnemonicArray: mnemonic)
        } catch {
            return false
        }
    }
}
