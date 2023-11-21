import Foundation
import TonSwift

public protocol Vault {
    associatedtype StoreValue
    associatedtype StoreKey
    
    func loadValue(key: StoreKey) throws -> StoreValue
}

public protocol StorableVault: Vault {
    func save(value: StoreValue, for key: StoreKey) throws
}
