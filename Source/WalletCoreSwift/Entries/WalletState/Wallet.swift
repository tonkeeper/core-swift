import Foundation

public struct Wallet {
    let publicKey: PublicKey
    let name: String?
    let active: WalletAddress
    let network: Network
    let backup: WalletBackup
    let tokenPolicy: WalletTokenPolicy
    let prefs: WalletPreferences
    let proxy: WalletProxy?
    let favorites: [WalletFavorite]?
}
