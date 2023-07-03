//
//  WalletContractBuilder.swift
//
//
//  Created by Grigory on 2.7.23..
//

import Foundation
import TonSwift

struct WalletContractBuilder {
    enum Error: Swift.Error {
        case notAvailableWalletRevision
    }
    func walletContract(with publicKey: TonSwift.PublicKey,
                        contractVersion: WalletContractVersion) throws -> WalletContract {
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
