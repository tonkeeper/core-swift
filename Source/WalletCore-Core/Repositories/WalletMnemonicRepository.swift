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
