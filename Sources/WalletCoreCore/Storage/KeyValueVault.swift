//
//  KeyValueVault.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation

protocol KeyValueVaultValue: Codable {
    associatedtype Key: CustomStringConvertible
}

public protocol Vault {
    associatedtype StoreValue
    func loadAllValues() throws -> [StoreValue]
    func deleteAllValues() throws
}

public protocol KeyValueVault {
    associatedtype StoreValue
    associatedtype StoreKey
    
    func loadValue(key: StoreKey) throws -> StoreValue
}

public protocol StorableKeyValueVault: KeyValueVault {
    func saveValue(_ value: StoreValue, for key: StoreKey) throws
    func deleteValue(for key: StoreKey) throws
}
