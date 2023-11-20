//
//  WalletMnemonicRepository.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation

public protocol WalletMnemonicRepository {
    func getMnemonic(wallet: Wallet) throws -> Mnemonic
    func saveMnemonic(_ mnemonic: Mnemonic, for wallet: Wallet) throws
}

extension MnemonicVault: WalletMnemonicRepository {
    func getMnemonic(wallet: Wallet) throws -> Mnemonic {
        try loadValue(key: wallet)
    }
    
    func saveMnemonic(_ mnemonic: Mnemonic, for wallet: Wallet) throws {
        try saveValue(mnemonic, for: wallet)
    }
}
