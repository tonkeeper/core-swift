//
//  WalletContractVersion.swift
//  
//
//  Created by Grigory Serebryanyy on 17.11.2023.
//

import Foundation

public enum WalletContractVersion: String, Codable {
    /// Wallet version is not applicable to this contract
    case NA
    /// Regular wallets
    case v3R1, v3R2, v4R1, v4R2
}
