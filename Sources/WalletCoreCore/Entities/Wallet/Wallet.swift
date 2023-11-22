//
//  Wallet.swift
//
//
//  Created by Grigory Serebryanyy on 17.11.2023.
//

import Foundation
import TonSwift

public struct Wallet: Codable, Hashable {
    /// Unique internal ID for this wallet
    public let identity: WalletIdentity
    
    /// Human-readable label. If empty, then it's rendered with a default title.
    public let label: String
    
    /// Per-wallet notifications: maybe filters by assets, amounts, dapps etc.
    let notificationSettings: NotificationSettings
    
    /// Backup settings for this wallet.
    public let backupSettings: WalletBackupSettings
    
    /// Preferred currency for all asset prices : TON, USD, EUR etc.
    public let currency: Currency
    
    /// List of remembered favorite addresses
    let addressBook: [AddressBookEntry]
    
    /// Preferred version out of `availableWalletVersions`.
    /// `nil` if the standard versions do not apply (lockup and watchonly wallets)
    public let contractVersion: WalletContractVersion
    
    /// Store your app-specific configuration here. Such as theme settings and other preferences.
    /// TODO: make this codeable so it can be backed up and sycned.
//    let userInfo: [String:AnyObject]
    
    /// If the wallet has potential sibling wallets, these are enumerated here.
    /// If the list has zero or 1 item, then UI should allow set `preferredVersion`
    func availableWalletVersions() -> [WalletContractVersion] {
        return []
    }
    
    public init(identity: WalletIdentity,
                label: String = "",
                notificationSettings: NotificationSettings = .init(),
                backupSettings: WalletBackupSettings = .init(enabled: true, revision: 1, voucher: nil),
                currency: Currency = .USD,
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
    
    public static func == (lhs: Wallet, rhs: Wallet) -> Bool {
        lhs.identity == rhs.identity
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(try? identity.id())
    }
}

extension Wallet {
    enum Error: Swift.Error {
        case notAvailableWalletKind
        case notAvailableWalletRevision
    }
    
    public var publicKey: TonSwift.PublicKey {
        get throws {
            switch identity.kind {
            case let .Regular(publicKey):
                return publicKey
            case let .External(publicKey):
                return publicKey
            default:
                throw Error.notAvailableWalletKind
            }
        }
    }
    
    public var contract: WalletContract {
        get throws {
            let publicKey = try publicKey
            switch contractVersion {
            case .v4R2:
                return WalletV4R2(publicKey: publicKey.data)
            case .v4R1:
                return WalletV4R1(publicKey: publicKey.data)
            case .v3R2:
                return try WalletV3(workchain: 0, publicKey: publicKey.data, revision: .r2)
            case .v3R1:
                return try WalletV3(workchain: 0, publicKey: publicKey.data, revision: .r1)
            case .NA:
                throw Error.notAvailableWalletRevision
            }
        }
    }
    
    public var stateInit: StateInit {
        get throws {
            try contract.stateInit
        }
    }
    
    public var address: Address {
        get throws {
            try contract.address()
        }
    }
    
    public var isRegular: Bool {
        guard case .Regular = identity.kind else {
            return false
        }
        return true
    }
    
    public var isExternal: Bool {
        guard case .External = identity.kind else {
            return false
        }
        return true
    }
}

extension Wallet {
    public func setCurrency(_ currency: Currency) -> Wallet {
        return .init(identity: self.identity,
                     label: self.label,
                     notificationSettings: self.notificationSettings,
                     backupSettings: self.backupSettings,
                     currency: currency,
                     addressBook: self.addressBook,
                     contractVersion: self.contractVersion)
    }
}
