import Foundation
import TonSwift

/// Shared interface for accessing any keys
public protocol Vault {
    func loadKey(publicKey: TonSwift.PublicKey) throws -> TonSwift.PrivateKey
}

/// Shared interface for storing keys
public protocol StorableVault {
    func saveKeyPair(_ keyPair: TonSwift.KeyPair) throws
}
