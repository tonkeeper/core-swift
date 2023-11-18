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

    init(identity: WalletIdentity,
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


