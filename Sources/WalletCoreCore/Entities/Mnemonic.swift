//
//  Mnemonic.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation
import TonSwift

public struct Mnemonic: Equatable, Codable {
    public enum Error: Swift.Error {
        case incorrectMnemonicWords
    }
    
    public var mnemonicWords: [String]
    
    public init(mnemonicWords: [String]) throws {
        guard TonSwift.Mnemonic.mnemonicValidate(mnemonicArray: mnemonicWords) else {
            throw Error.incorrectMnemonicWords
        }
        self.mnemonicWords = mnemonicWords
    }
    
    public init(from decoder: Decoder) throws {
        if var arrayContainer = try? decoder.unkeyedContainer() {
            let words = try arrayContainer.decode(String.self).components(separatedBy: ",")
            self.mnemonicWords = words
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.mnemonicWords = try container.decode([String].self, forKey: .mnemonicWords)
    }
}
