import Foundation
import TonSwift

struct VaultPublicKey {
    let pubkey: Data // TODO: change for statically-sized type from Ton Swift
}

struct VaultPrivateKey {
    let privkey: Data // TODO: change for statically-sized type from Ton Swift
}

/// Shared interface for accessing any keys
public protocol Vault {
    func loadKey(pubkey: VaultPublicKey) -> VaultSecretKey
}
