//
//  Wallet.swift
//
//
//  Created by Grigory on 3.10.23..
//


import Foundation

extension Wallet {
    func setCurrency(_ currency: Currency) -> Wallet {
        return .init(identity: self.identity,
                     label: self.label,
                     notificationSettings: self.notificationSettings,
                     backupSettings: self.backupSettings,
                     currency: currency,
                     addressBook: self.addressBook,
                     contractVersion: self.contractVersion)
    }
}
