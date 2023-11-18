//
//  WalletMnemonicMockRepository.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation
@testable import WalletCore_Core

final class WalletMnemonicMockRepository: WalletMnemonicRepository {
    
    enum Error: Swift.Error {
        case noMnemonic
    }
    
    var mnemonics = [WalletID: Mnemonic]()
    
    func getMnemonic(wallet: WalletCore_Core.Wallet) throws -> WalletCore_Core.Mnemonic {
        guard let mnemonic = mnemonics[try wallet.identity.id()] else {
            throw Error.noMnemonic
        }
        return mnemonic
    }
    
    func saveMnemonic(_ mnemonic: WalletCore_Core.Mnemonic, for wallet: WalletCore_Core.Wallet) throws {
        mnemonics[try wallet.identity.id()] = mnemonic
    }
    
    func reset() {
        mnemonics = [:]
    }
}
