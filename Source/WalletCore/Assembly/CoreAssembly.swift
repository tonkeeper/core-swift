//
//  CoreAssembly.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation

final class CoreAssembly {
    var encoder: JSONEncoder {
        JSONEncoder()
    }
    
    var decoder: JSONDecoder {
        JSONDecoder()
    }
    
    var fileManager: FileManager {
        .default
    }
    
    var keychainManager: KeychainManager {
        KeychainManager(keychain: keychain)
    }
    
    var keychain: Keychain {
        KeychainImplementation()
    }
    
    var keychainPasscodeVault: KeychainPasscodeVault {
        KeychainPasscodeVault(keychainManager: keychainManager)
    }
    
    func keychainMnemonicVault(keychainGroup: String) -> KeychainMnemonicVault {
        KeychainMnemonicVault(keychainManager: keychainManager, keychainGroup: keychainGroup)
    }
}
