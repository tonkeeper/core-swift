import Foundation
import CoreComponents

public protocol KeeperInfoService {
  func getKeeperInfo() throws -> KeeperInfo
  func deleteKeeperInfo() throws
  func addWallet(_ wallet: Wallet, setActive: Bool) throws
}

final class KeeperInfoServiceImplementation: KeeperInfoService {
  private let keeperInfoRepository: KeeperInfoRepository
  
  init(keeperInfoRepository: KeeperInfoRepository) {
    self.keeperInfoRepository = keeperInfoRepository
  }
  
  func getKeeperInfo() throws -> KeeperInfo {
    return try keeperInfoRepository.getKeeperInfo()
  }
  
  func deleteKeeperInfo() throws {
    try keeperInfoRepository.removeKeeperInfo()
  }
  
  func addWallet(_ wallet: Wallet, setActive: Bool) throws {
    let keeperInfo: KeeperInfo
    if let savedKeeperInfo = try? keeperInfoRepository.getKeeperInfo() {
      keeperInfo = addWallet(
        wallet,
        setActive: setActive,
        keeperInfo: savedKeeperInfo
      )
    } else {
      keeperInfo = createKeeperInfo(withWallet: wallet)
    }
    
    try keeperInfoRepository.saveKeeperInfo(keeperInfo)
  }
}

private extension KeeperInfoServiceImplementation {
  func addWallet(_ wallet: Wallet,
                 setActive: Bool,
                 keeperInfo: KeeperInfo) -> KeeperInfo {
    var keeperInfoWallets = keeperInfo.wallets
    if let walletIndex = keeperInfoWallets.firstIndex(of: wallet) {
      keeperInfoWallets.remove(at: walletIndex)
      keeperInfoWallets.insert(wallet, at: walletIndex)
    } else {
      keeperInfoWallets.append(wallet)
    }
    
    let updatedKeeperInfo = KeeperInfo(
      wallets: keeperInfoWallets,
      currentWallet: setActive ? wallet.identity : keeperInfo.currentWallet,
      securitySettings: keeperInfo.securitySettings,
      assetsPolicy: keeperInfo.assetsPolicy,
      appCollection: keeperInfo.appCollection
    )
    return updatedKeeperInfo
  }
  
  func createKeeperInfo(withWallet wallet: Wallet) -> KeeperInfo {
    KeeperInfo(wallets: [wallet],
               currentWallet: wallet.identity,
               securitySettings: SecuritySettings(isBiometryEnabled: false),
               assetsPolicy: AssetsPolicy(policies: [:], ordered: []),
               appCollection: AppCollection(connected: [:], recent: [], pinned: []))
  }
}

