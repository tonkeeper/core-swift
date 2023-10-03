//
//  KeeperController.swift
//  
//
//  Created by Grigory on 27.6.23..
//

import Foundation
import TonSwift

public protocol WalletProviderObserver: AnyObject {
    func didUpdateActiveWallet()
}

public protocol WalletProvider {
    var activeWallet: Wallet { get throws }
    
    func addObserver(_ observer: WalletProviderObserver)
    func removeObserver(_ observer: WalletProviderObserver)
}

public final class KeeperController: WalletProvider {
    private let keeperService: KeeperInfoService
    private let keychainManager: KeychainManager
    private let keychainGroup: String
    
    public var hasWallets: Bool {
        checkIfKeeperHasValidWallets()
    }
    
    init(keeperService: KeeperInfoService,
         keychainManager: KeychainManager,
         keychainGroup: String) {
        self.keeperService = keeperService
        self.keychainManager = keychainManager
        self.keychainGroup = keychainGroup
    }
    
    public var activeWallet: Wallet {
        get throws {
            let keeperInfo = try keeperService.getKeeperInfo()
            return keeperInfo.currentWallet
        }
    }
    
    public func addWallet(with mnemonic: [String]) throws {
        let keyPair = try Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonic)
        let wallet = Wallet(identity: WalletIdentity(network: .mainnet,
                                                     kind: .Regular(keyPair.publicKey)),
                            notificationSettings: .init(),
                            backupSettings: .init(enabled: true, revision: 1, voucher: nil),
                            currency: .USD,
                            contractVersion: .v4R2)
        let mnemonicVault = KeychainMnemonicVault(
            keychainManager: keychainManager,
            walletID: try wallet.identity.id(),
            keychainGroup: keychainGroup
        )
        try mnemonicVault.save(value: mnemonic, for: keyPair.publicKey)
        try updateKeeperInfo(with: wallet)
    }
    
    public func update(wallet: Wallet, currency: Currency) throws {
        let updatedWallet = wallet.setCurrency(currency)
        let keeperInfo = try keeperService.getKeeperInfo().updateWallet(updatedWallet)
        try keeperService.saveKeeperInfo(keeperInfo)
        notifyObservers()
    }
    
    private var observers = [WalletProviderObserverWrapper]()
    
    struct WalletProviderObserverWrapper {
      weak var observer: WalletProviderObserver?
    }
    
    public func addObserver(_ observer: WalletProviderObserver) {
        observers.append(.init(observer: observer))
    }
    
    public func removeObserver(_ observer: WalletProviderObserver) {
        observers = observers.filter { $0.observer !== observer }
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
            let mnemonicVault = KeychainMnemonicVault(
                keychainManager: keychainManager,
                walletID: try wallet.identity.id(),
                keychainGroup: keychainGroup)
            let mnemonic = try mnemonicVault.loadValue(key: publicKey)
            return Mnemonic.mnemonicValidate(mnemonicArray: mnemonic)
        } catch {
            return false
        }
    }
    
    func notifyObservers() {
      observers = observers.filter { $0.observer != nil }
      observers.forEach { $0.observer?.didUpdateActiveWallet() }
    }
}
