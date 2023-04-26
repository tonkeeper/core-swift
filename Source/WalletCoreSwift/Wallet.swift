import Foundation
import TonSwift

/*
 
 TODO:
 - Q: "fast unlock" VS "lock screen" setting
 - Q: notification settings per app VS per wallet
 - Q: dapp notification settings? per app / per wallet
 - Q: how to share passcode?
*/


/// Represents the entire state of the application install
public struct KeeperInfo {
    /// Keeper contains multiple wallets
    let wallets: [Wallet]
    
    /// Currently selected wallet
    let currentWallet: Wallet
    
    /// Common pin/faceid settings
    let securitySettings: SecuritySettings
    
    ///
    let assetsPolicy: AssetsPolicy
    let appCollection: AppCollection
}

struct AppCollection {
    let connected: [WalletID: AppConnection]
    let recent: [AppID]
    let pinned: [AppID]
}

typealias AppID = String
struct AppConnection {
    let id: AppID
    // TBD: a bunch of ton connect stuff
    let sessionID: Data
    
    // TODO: notif preferences
    let notifications: Bool
}


/// Shared security settings for all wallets in the app
struct SecuritySettings {
    // biometrics
    // passcode
    // lock screen
    // hidden balances
}


/// Specifies whitelisted/blacklisted tokens, issuers, collections.
struct AssetsPolicy {
    /// TODO: revise these
    /// we need to remember issues/collections instead of individual tokens.
    /// change to `Address`
    let hiddenJettons: [String]?
    let shownJettons: [String]?
    let orderJettons: [String]?
}

struct NotificationSettings {
    
}

struct WalletID: Hashable { // TBD: Comparable
    let hash: Data
}

public struct WalletIdentity {
    let network: Network
    let kind: WalletKind
    
    func id() -> WalletID {
        // TBD: hash the contents to produce deterministic wallet id
        // Use TL-B cell's representationHash()
        return WalletID(hash: Data())
    }
}

enum WalletKind {
    case Regular(PublicKey)
    case Lockup(PublicKey, LockupConfig)
    case Watchonly(TonSwift.Address)
}

struct LockupConfig {
    // TBD: lockup-1.0 config
}

public struct Wallet {
    /// Unique internal ID for this wallet
    let identity: WalletIdentity
    
    /// Human-readable label. If empty, then it's rendered with a default title.
    let label: String = ""
    
    /// Per-wallet notifications: maybe filters by assets, amounts, dapps etc.
    let notificationSettings: NotificationSettings
    
    /// Backup settings for this wallet.
    let backupSettings: WalletBackupSettings
    
    /// Preferred currency for all asset prices : TON, USD, EUR etc.
    let currency: Currency = Currency.TON
    
    /// List of remembered favorite addresses
    let favorites: [FavoriteAddress] = []
    
    /// Preferred version out of `availableWalletVersions`.
    /// `nil` if the standard versions do not apply (lockup and watchonly wallets)
    let contractVersion: WalletContractVersion = .NA
    
    /// Store your app-specific configuration here. Such as theme settings and other preferences.
    /// TODO: make this codeable so it can be backed up and sycned.
    let userInfo: [String:AnyObject]
    
    /// If the wallet has potential sibling wallets, these are enumerated here.
    /// If the list has zero or 1 item, then UI should allow set `preferredVersion`
    func availableWalletVersions() -> [WalletContractVersion] {
        return []
    }
    
//    func address() -> TonSwift.Address {
//        // TBD: construct wallet with the given settings and version and return its address
//
//    }
}

public enum WalletContractVersion: String {
    /// Wallet version is not applicable to this contract
    case NA
    /// Regular wallets 
    case v3R1, v3R2, v4R1, v4R2
}

enum Network: Int {
    case mainnet = -239
    case testnet = -3
}


// TODO: revise
public typealias PublicKey = String
public typealias SecretKey = String
public typealias SharedKey = String

// TODO: revise
public struct WalletVoucher {
    let publicKey: PublicKey
    let secretKey: SecretKey
    let sharedKey: SharedKey
    let voucher: String
}

// TODO: revise
public struct WalletBackupSettings {
    // TBD: revisit these
    let enabled: Bool
    let revision: Int
    let voucher: WalletVoucher?
}


/// Human-visible address that can be resolved dynamically
enum ResolvableAddress: Hashable {
    /// Raw TON address (e.g. "EQf85gAj...")
    case Resolved(TonSwift.Address)
    /// TON.DNS name (e.g. "oleganza.ton")
    case Domain(String)
}

struct FavoriteAddress {
    let addr: ResolvableAddress
    let label: String
}


