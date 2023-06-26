import Foundation
import TonSwift

public struct VaultPublicKey {
    let pubkey: Data // TODO: change for statically-sized type from Ton Swift
}

public struct VaultSecretKey {
    let privkey: Data // TODO: change for statically-sized type from Ton Swift
}

/// Shared interface for accessing any keys
public protocol Vault {
    func loadKey(pubkey: VaultPublicKey) -> VaultSecretKey
}
