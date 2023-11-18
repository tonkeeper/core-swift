//
//  KeeperInfoService.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation

final class KeeperInfoService {
    private let keeperInfoRepository: KeeperInfoRepository
    
    init(keeperInfoRepository: KeeperInfoRepository) {
        self.keeperInfoRepository = keeperInfoRepository
    }
    
    func getKeeperInfo() throws -> KeeperInfo {
        try keeperInfoRepository.getKeeperInfo()
    }
    
    func saveKeeperInfo(_ keeperInfo: KeeperInfo) throws {
        try keeperInfoRepository.saveKeeperInfo(keeperInfo)
    }
    
    func deleteKeeperInfo() throws {
        try keeperInfoRepository.removeKeeperInfo()
    }
    
    func updateKeeperInfo(with wallet: Wallet) throws {
        var keeperInfo: KeeperInfo
        do {
            keeperInfo = try getKeeperInfo()
            var wallets = keeperInfo.wallets
            if let oldWalletIndex = wallets.firstIndex(of: wallet) {
                wallets.remove(at: oldWalletIndex)
                wallets.insert(wallet, at: oldWalletIndex)
            } else {
                wallets.append(wallet)
            }
            
            keeperInfo = KeeperInfo(
                wallets: wallets,
                currentWallet: keeperInfo.currentWallet,
                securitySettings: keeperInfo.securitySettings,
                assetsPolicy: keeperInfo.assetsPolicy,
                appCollection: keeperInfo.appCollection
            )
        } catch {
            keeperInfo = createKeeperInfo(with: wallet)
        }
        try saveKeeperInfo(keeperInfo)
    }
}

private extension KeeperInfoService {
    func createKeeperInfo(with wallet: Wallet) -> KeeperInfo {
        KeeperInfo(
            wallets: [wallet],
            currentWallet: wallet.identity,
            securitySettings: .init(isBiometryEnabled: false),
            assetsPolicy: .init(policies: [:], ordered: []),
            appCollection: .init(connected: [:], recent: [], pinned: [])
        )
    }
}
