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
public struct KeeperInfo: Codable {
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

struct AppCollection: Codable {
    let connected: [WalletID: AppConnection]
    let recent: [AppID]
    let pinned: [AppID]
}

typealias AppID = String
struct AppConnection: Codable {
    let id: AppID
    // TBD: a bunch of ton connect stuff
    let sessionID: Data
    
    // TODO: notif preferences
    let notifications: Bool
}


/// Shared security settings for all wallets in the app
struct SecuritySettings {
    let isBiometryEnabled: Bool
    // passcode
    // lock screen
    // hidden balances
}

extension SecuritySettings: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isBiometryEnabled = (try? container.decode(Bool.self, forKey: .isBiometryEnabled)) ?? false
    }
}

struct NotificationSettings: Codable {
    
}

struct WalletID: Hashable, Codable { // TBD: Comparable
    var string: String {
        hash.hexString()
    }
    
    let hash: Data
}

public struct WalletIdentity {
    let network: Network
    let kind: WalletKind
    
    func id() throws -> WalletID {
        let builder = Builder()
        try builder.store(self)
        return WalletID(hash: try builder.endCell().representationHash())
    }
}

extension WalletIdentity: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let identityBinaryString = try container.decode(String.self)
        let identityBitstring = try Bitstring(binaryString: identityBinaryString)
        self = try Slice(bits: identityBitstring).loadType()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let identityBinaryString = try Builder().store(self).bitstring().toBinary()
        try container.encode(identityBinaryString)
    }
}

enum WalletKind {
    case Regular(TonSwift.PublicKey)
    case Lockup(TonSwift.PublicKey, LockupConfig)
    case Watchonly(ResolvableAddress)
}

struct LockupConfig: Equatable {
    // TBD: lockup-1.0 config
}

public struct Wallet: Codable, Hashable {
    public static func == (lhs: Wallet, rhs: Wallet) -> Bool {
        do {
            return try lhs.identity.id() == rhs.identity.id()
        } catch {
            return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(try? identity.id())
    }
    
    /// Unique internal ID for this wallet
    let identity: WalletIdentity
    
    /// Human-readable label. If empty, then it's rendered with a default title.
    let label: String
    
    /// Per-wallet notifications: maybe filters by assets, amounts, dapps etc.
    let notificationSettings: NotificationSettings
    
    /// Backup settings for this wallet.
    let backupSettings: WalletBackupSettings
    
    /// Preferred currency for all asset prices : TON, USD, EUR etc.
    public let currency: Currency
    
    /// List of remembered favorite addresses
    let addressBook: [AddressBookEntry]
    
    /// Preferred version out of `availableWalletVersions`.
    /// `nil` if the standard versions do not apply (lockup and watchonly wallets)
    let contractVersion: WalletContractVersion
    
    /// Store your app-specific configuration here. Such as theme settings and other preferences.
    /// TODO: make this codeable so it can be backed up and sycned.
//    let userInfo: [String:AnyObject]
    
    /// If the wallet has potential sibling wallets, these are enumerated here.
    /// If the list has zero or 1 item, then UI should allow set `preferredVersion`
    func availableWalletVersions() -> [WalletContractVersion] {
        return []
    }
    
    
    
//    func address() -> TonSwift.Address {
//        // TBD: construct wallet with the given settings and version and return its address
//
//    }
    
    init(identity: WalletIdentity,
         label: String = "",
         notificationSettings: NotificationSettings,
         backupSettings: WalletBackupSettings,
         currency: Currency = .TON,
         addressBook: [AddressBookEntry] = [],
         contractVersion: WalletContractVersion = .NA) {
        self.identity = identity
        self.label = label
        self.notificationSettings = notificationSettings
        self.backupSettings = backupSettings
        self.currency = currency
        self.addressBook = addressBook
        self.contractVersion = contractVersion
    }
}

public enum WalletContractVersion: String, Codable {
    /// Wallet version is not applicable to this contract
    case NA
    /// Regular wallets 
    case v3R1, v3R2, v4R1, v4R2
}

enum Network: Int16 {
    case mainnet = -239
    case testnet = -3
}


// TODO: revise
public typealias PublicKey = String
public typealias SecretKey = String
public typealias SharedKey = String

// TODO: revise
public struct WalletVoucher: Codable {
    let publicKey: PublicKey
    let secretKey: SecretKey
    let sharedKey: SharedKey
    let voucher: String
}

// TODO: revise
public struct WalletBackupSettings: Codable {
    // TBD: revisit these
    let enabled: Bool
    let revision: Int
    let voucher: WalletVoucher?
}


/// Human-visible address that can be resolved dynamically
enum ResolvableAddress: Hashable, Codable {
    /// Raw TON address (e.g. "EQf85gAj...")
    case Resolved(TonSwift.Address)
    /// TON.DNS name (e.g. "oleganza.ton")
    case Domain(String)
}

struct AddressBookEntry: Codable {
    let address: ResolvableAddress
    let label: String
}


