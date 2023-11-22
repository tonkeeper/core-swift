//
//  MockWalletProvider.swift
//
//
//  Created by Grigory Serebryanyy on 22.11.2023.
//

import Foundation
import WalletCoreCore
import TonSwift

struct MockWalletProvider: WalletProvider {
    
    enum Error: Swift.Error {
        case noActiveWallet
        case noWalletPrivateKey
        case noWalletMnemonic
    }
    
    var _activeWallet: Wallet?
    var _wallets = [Wallet]()
    var _privateKeys = [Wallet: TonSwift.PrivateKey]()
    var _mnemonics = [Wallet: WalletCoreCore.Mnemonic]()
    
    var wallets: [Wallet] {
        _wallets
    }
    var activeWallet: Wallet {
        get throws {
            guard let _activeWallet = _activeWallet else { throw Error.noActiveWallet }
            return _activeWallet
        }
    }
    var hasWallets: Bool {
        !wallets.isEmpty
    }
    
    func getWalletPrivateKey(_ wallet: WalletCoreCore.Wallet) throws -> TonSwift.PrivateKey {
        guard let privateKey = _privateKeys[wallet] else { throw Error.noWalletPrivateKey }
        return privateKey
    }
    
    func getWalletMnemonic(_ wallet: WalletCoreCore.Wallet) throws -> WalletCoreCore.Mnemonic {
        guard let mnemonic = _mnemonics[wallet] else { throw Error.noWalletMnemonic }
        return mnemonic
    }
    
    func addObserver(_ observer: WalletCoreCore.WalletProviderObserver) {}
    
    func removeObserver(_ observer: WalletCoreCore.WalletProviderObserver) {}
}
