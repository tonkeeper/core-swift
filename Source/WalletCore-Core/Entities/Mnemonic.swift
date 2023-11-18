//
//  Mnemonic.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation
import TonSwift

public struct Mnemonic: Equatable {
    public enum Error: Swift.Error {
        case incorrectMnemonicWords
    }
    
    public let mnemonicWords: [String]
    
    public init(mnemonicWords: [String]) throws {
        guard TonSwift.Mnemonic.mnemonicValidate(mnemonicArray: mnemonicWords) else {
            throw Error.incorrectMnemonicWords
        }
        self.mnemonicWords = mnemonicWords
    }
}
