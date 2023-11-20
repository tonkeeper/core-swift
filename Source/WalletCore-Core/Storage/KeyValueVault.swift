//
//  KeyValueVault.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation

protocol KeyValueVaultValue: Codable {
    associatedtype Key: CustomStringConvertible
    var key: Key { get }
}

public protocol KeyValueVault {
    associatedtype StoreValue
    associatedtype StoreKey
    
    func loadValue(key: StoreKey) throws -> StoreValue
    func loadAllValues() throws -> [StoreValue]
}

public protocol StorableVault: KeyValueVault {
    func saveValue(_ value: StoreValue, for key: StoreKey) throws
    func deleteValue(for key: StoreKey) throws
    func deleteAllValues() throws
}
