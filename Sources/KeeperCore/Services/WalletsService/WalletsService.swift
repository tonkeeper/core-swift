import Foundation
import CoreComponents

enum WalletsServiceError: Swift.Error {
  case emptyWallets
  case walletNotAdded
  case incorrectMoveFromIndex
  case incorrectMoveToIndex
  case incorrectActiveWalletIdentity
}

public protocol WalletsService {
  func getWallets() throws -> [Wallet]
  func getActiveWallet() throws -> Wallet
  func addWallets(_ wallets: [Wallet]) throws
  func setWalletActive(_ wallet: Wallet) throws
  func moveWallet(fromIndex: Int, toIndex: Int) throws
}

final class WalletsServiceImplementation: WalletsService {
  let keeperInfoRepository: KeeperInfoRepository
  
  init(keeperInfoRepository: KeeperInfoRepository) {
    self.keeperInfoRepository = keeperInfoRepository
  }
  
  func getWallets() throws -> [Wallet] {
    try keeperInfoRepository.getKeeperInfo().wallets
  }
  
  func getActiveWallet() throws -> Wallet {
    let keeperInfo = try keeperInfoRepository.getKeeperInfo()
    return keeperInfo.currentWallet
  }
  
  func addWallets(_ wallets: [Wallet]) throws {
    guard !wallets.isEmpty else { throw WalletsServiceError.emptyWallets }
    
    let keeperInfo: KeeperInfo
    do {
      let currentKeeperInfo = try keeperInfoRepository.getKeeperInfo()
      let newWalletsIds = wallets.map { $0.identity }
      let updatedWallets = currentKeeperInfo.wallets.filter { !newWalletsIds.contains($0.identity) } + wallets
      let updatedKeeperInfo = currentKeeperInfo.setWallets(updatedWallets)
      keeperInfo = updatedKeeperInfo
    } catch {
      keeperInfo = createKeeperInfo(wallets: wallets)
    }
    
    try keeperInfoRepository.saveKeeperInfo(keeperInfo)
  }
  
  func setWalletActive(_ wallet: Wallet) throws {
    let currentKeeperInfo = try keeperInfoRepository.getKeeperInfo()
    guard currentKeeperInfo.wallets.contains(where: { $0.identity == wallet.identity }) else {
      throw WalletsServiceError.walletNotAdded
    }
    let updatedKeeperInfo = currentKeeperInfo.setActiveWallet(wallet)
    try keeperInfoRepository.saveKeeperInfo(updatedKeeperInfo)
  }
  
  func moveWallet(fromIndex: Int, toIndex: Int) throws  {
    let currentKeeperInfo = try keeperInfoRepository.getKeeperInfo()
    guard fromIndex < currentKeeperInfo.wallets.count, fromIndex >= 0 else { throw WalletsServiceError.incorrectMoveFromIndex }
    guard toIndex < currentKeeperInfo.wallets.count, toIndex >= 0 else { throw WalletsServiceError.incorrectMoveFromIndex }
    var wallets = currentKeeperInfo.wallets
    let wallet = wallets.remove(at: fromIndex)
    wallets.insert(wallet, at: toIndex)
    let updatedKeeperInfo = currentKeeperInfo.setWallets(wallets)
    try keeperInfoRepository.saveKeeperInfo(updatedKeeperInfo)
  }
}

private extension WalletsServiceImplementation {
  func createKeeperInfo(wallets: [Wallet]) -> KeeperInfo {
    let keeperInfo = KeeperInfo(
      wallets: wallets,
      currentWallet: wallets[0],
      securitySettings: SecuritySettings(isBiometryEnabled: false),
      assetsPolicy: AssetsPolicy(policies: [:], ordered: []),
      appCollection: AppCollection(connected: [:], recent: [], pinned: [])
    )
    return keeperInfo
  }
}
