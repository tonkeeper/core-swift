//
//  WalletsController.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation
import TonSwift

public protocol WalletsControllerObserver: AnyObject {
    func walletsController(_ walletsController: WalletsController, didAddWallet wallet: Wallet)
    func walletsController(_ walletsController: WalletsController, didChangeActiveWallet wallet: Wallet)
}

public final class WalletsController {
    enum Error: Swift.Error {
        case noActiveWallet
    }
    
    private let keeperInfoService: KeeperInfoService
    private let walletMnemonicRepository: WalletMnemonicRepository
    
    init(keeperInfoService: KeeperInfoService,
         walletMnemonicRepository: WalletMnemonicRepository) {
        self.keeperInfoService = keeperInfoService
        self.walletMnemonicRepository = walletMnemonicRepository
    }
    
    public var hasWallets: Bool {
        !getValidWallets().isEmpty
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
    
    public func addWallet(with mnemonic: Mnemonic) throws {
        let keyPair = try TonSwift.Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonic.mnemonicWords)
        let wallet = Wallet(identity: .init(network: .mainnet, kind: .Regular(keyPair.publicKey)))
        try walletMnemonicRepository.saveMnemonic(mnemonic, for: wallet)
        try keeperInfoService.updateKeeperInfo(with: wallet)
        notifyObserversWalletAdded(wallet: wallet)
    }
    
    // MARK: - Observering
    
    struct WalletsControllerObserverWrapper {
        weak var observer: WalletsControllerObserver?
    }
    
    private var observers = [WalletsControllerObserverWrapper]()
    
    public func addObserver(_ observer: WalletsControllerObserver) {
        removeNilObservers()
        observers = observers + CollectionOfOne(WalletsControllerObserverWrapper.init(observer: observer))
    }
    
    public func removeObserver(_ observer: WalletsControllerObserver) {
        removeNilObservers()
        observers = observers.filter { $0.observer !== observer }
    }
}

private extension WalletsController {
    func getWalletMnemonic(_ wallet: Wallet) throws -> Mnemonic {
        try walletMnemonicRepository.getMnemonic(wallet: wallet)
    }
    
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
        observers.forEach { $0.observer?.walletsController(self, didAddWallet: wallet) }
    }
    
    func notifyObserversActiveWalletChanged(wallet: Wallet) {
        observers.forEach { $0.observer?.walletsController(self, didChangeActiveWallet: wallet) }
    }
}
