//
//  KeychainRestore.swift
//
//
//  Created by Grigory on 1.10.23..
//

import Foundation
import TonSwift

public struct KeychainRestore {
    public init() {}
    
    public func findAllItems() -> [[String]] {
        let requestDictionary: [CFString: AnyObject] = [
            kSecClass: kSecClassGenericPassword as AnyObject,
            kSecReturnData: true as AnyObject,
            kSecMatchLimit: kSecMatchLimitAll as AnyObject
        ]
        
        var resultValue: AnyObject?
        let resultCode = withUnsafeMutablePointer(to: &resultValue) {
            SecItemCopyMatching(requestDictionary as CFDictionary, UnsafeMutablePointer($0))
        }
        if let resultValue = resultValue as? [Data] {
            let mnemonics = resultValue.compactMap { data -> [String]? in
                guard var string = String(data: data, encoding: .utf8) else { return nil }
                string = string.replacingOccurrences(of: "[", with: "")
                string = string.replacingOccurrences(of: "\\", with: "")
                string = string.replacingOccurrences(of: "\"", with: "")
                string = string.replacingOccurrences(of: "]", with: "")
                let mnemonic = string.components(separatedBy: ",")
                guard Mnemonic.mnemonicValidate(mnemonicArray: mnemonic) else { return nil }
                return mnemonic
            }
            return mnemonics
        }
        return []
    }
}
