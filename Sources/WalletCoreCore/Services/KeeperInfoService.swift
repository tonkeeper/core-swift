//
//  KeeperInfoService.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation

public protocol KeeperInfoServiceObserver: AnyObject {
    func keeperInfoService(_ keeperInfoService: KeeperInfoService, didUpdateActiveWallet wallet: Wallet)
}

public final class KeeperInfoService {
    private let keeperInfoRepository: KeeperInfoRepository
    
    init(keeperInfoRepository: KeeperInfoRepository) {
        self.keeperInfoRepository = keeperInfoRepository
    }
    
    public func getKeeperInfo() throws -> KeeperInfo {
        try keeperInfoRepository.getKeeperInfo()
    }
    
    public func saveKeeperInfo(_ keeperInfo: KeeperInfo) throws {
        try keeperInfoRepository.saveKeeperInfo(keeperInfo)
    }
    
    public func deleteKeeperInfo() throws {
        try keeperInfoRepository.removeKeeperInfo()
    }
    
    public func updateKeeperInfo(with wallet: Wallet) throws {
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
        if wallet.identity == keeperInfo.currentWallet {
            notifyObserversActiveWalletUpdated(wallet: wallet)
        }
    }
    
    // MARK: - Observering
    
    struct KeeperInfoServiceObserverWrapper {
        weak var observer: KeeperInfoServiceObserver?
    }
    
    private var observers = [KeeperInfoServiceObserverWrapper]()
    
    public func addObserver(_ observer: KeeperInfoServiceObserver) {
        removeNilObservers()
        observers = observers + CollectionOfOne(KeeperInfoServiceObserverWrapper(observer: observer))
    }
    
    public func removeObserver(_ observer: KeeperInfoServiceObserver) {
        removeNilObservers()
        observers = observers.filter { $0.observer !== observer }
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
    
    func removeNilObservers() {
        observers = observers.filter { $0.observer != nil }
    }
    
    func notifyObserversActiveWalletUpdated(wallet: Wallet) {
        observers.forEach { $0.observer?.keeperInfoService(self, didUpdateActiveWallet: wallet) }
    }
}
