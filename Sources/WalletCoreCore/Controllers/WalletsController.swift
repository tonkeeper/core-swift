//
//  WalletsController.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation
import TonSwift

public protocol WalletProvider {
    var wallets: [Wallet] { get }
    var activeWallet: Wallet { get throws }
    var hasWallets: Bool { get }
    
    func getWalletPrivateKey(_ wallet: Wallet) throws -> TonSwift.PrivateKey
    func getWalletMnemonic(_ wallet: Wallet) throws -> Mnemonic
    
    func addObserver(_ observer: WalletProviderObserver)
    func removeObserver(_ observer: WalletProviderObserver)
}

public protocol WalletProviderObserver: AnyObject {
    func walletProvider(_ walletProvider: WalletProvider, didAddWallet wallet: Wallet)
    func walletProvider(_ walletProvider: WalletProvider, didUpdateActiveWallet wallet: Wallet)
}

public extension WalletProviderObserver {
    func walletProvider(_ walletProvider: WalletProvider, didAddWallet wallet: Wallet) {}
    func walletProvider(_ walletProvider: WalletProvider, didUpdateActiveWallet wallet: Wallet) {}
}

public final class WalletsController: WalletProvider {
    enum Error: Swift.Error {
        case noActiveWallet
        case noWalletPrivateKey
    }
    
    private let keeperInfoService: KeeperInfoService
    private let walletMnemonicRepository: WalletMnemonicRepository
    
    init(keeperInfoService: KeeperInfoService,
         walletMnemonicRepository: WalletMnemonicRepository) {
        self.keeperInfoService = keeperInfoService
        self.walletMnemonicRepository = walletMnemonicRepository
        keeperInfoService.addObserver(self)
    }
    
    public var hasWallets: Bool {
        !getValidWallets().isEmpty
    }
    
    public var wallets: [Wallet] {
        getValidWallets()
    }
    
    public var activeWallet: Wallet {
        get throws {
            let keeperInfo = try keeperInfoService.getKeeperInfo()
            guard let wallet = getValidWallets().first(where: { $0.identity == keeperInfo.currentWallet }) else {
                throw Error.noActiveWallet
            }
            return wallet
        }
    }
    
    public func addWallet(with mnemonic: Mnemonic,
                          label: String) throws {
        let keyPair = try TonSwift.Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonic.mnemonicWords)
        let wallet = Wallet(
          identity: .init(network: .mainnet, 
                          kind: .Regular(keyPair.publicKey)),
          label: label,
          contractVersion: .v4R2
        )
        try walletMnemonicRepository.saveMnemonic(mnemonic, for: wallet)
        try keeperInfoService.updateKeeperInfo(with: wallet)
        notifyObserversWalletAdded(wallet: wallet)
    }
    
    public func addExternalWallet(with publicKey: TonSwift.PublicKey,
                                  label: String) throws {
        let wallet = Wallet(
          identity: .init(network: .mainnet, 
                          kind: .External(publicKey)),
          label: label)
        try keeperInfoService.updateKeeperInfo(with: wallet)
        notifyObserversWalletAdded(wallet: wallet)
    }
    
    public func getWalletPrivateKey(_ wallet: Wallet) throws -> TonSwift.PrivateKey {
        switch wallet.identity.kind {
        case .Regular:
            let walletMnemonic = try walletMnemonicRepository.getMnemonic(wallet: wallet)
            return try TonSwift.Mnemonic.mnemonicToPrivateKey(mnemonicArray: walletMnemonic.mnemonicWords).privateKey
        default:
            throw Error.noWalletPrivateKey
        }
    }
    
    public func getWalletMnemonic(_ wallet: Wallet) throws -> Mnemonic {
        try walletMnemonicRepository.getMnemonic(wallet: wallet)
    }
    
    // MARK: - Observering
    
    struct WalletProviderObserverWrapper {
        weak var observer: WalletProviderObserver?
    }
    
    private var observers = [WalletProviderObserverWrapper]()
    
    public func addObserver(_ observer: WalletProviderObserver) {
        removeNilObservers()
        observers = observers + CollectionOfOne(WalletProviderObserverWrapper(observer: observer))
    }
    
    public func removeObserver(_ observer: WalletProviderObserver) {
        removeNilObservers()
        observers = observers.filter { $0.observer !== observer }
    }
}

extension WalletsController: KeeperInfoServiceObserver {
    public func keeperInfoService(_ keeperInfoService: KeeperInfoService, didUpdateActiveWallet wallet: Wallet) {
        notifyObserversActiveWalletUpdated(wallet: wallet)
    }
}

private extension WalletsController {
    func getValidWallets() -> [Wallet] {
        do {
            let wallets = try keeperInfoService.getKeeperInfo().wallets
            guard !wallets.isEmpty else { return wallets }
            let validWallets = wallets.filter { wallet in
                switch wallet.identity.kind {
                case .Regular:
                    return (try? getWalletMnemonic(wallet)) != nil
                case .Lockup:
                    return false
                case .Watchonly:
                    return false
                case .External:
                    return true
                }
            }
            return validWallets
        } catch {
            return []
        }
    }
    
    func removeNilObservers() {
        observers = observers.filter { $0.observer != nil }
    }
    
    func notifyObserversWalletAdded(wallet: Wallet) {
        observers.forEach { $0.observer?.walletProvider(self, didAddWallet: wallet) }
    }
    
    func notifyObserversActiveWalletUpdated(wallet: Wallet) {
        observers.forEach { $0.observer?.walletProvider(self, didUpdateActiveWallet: wallet) }
    }
}
