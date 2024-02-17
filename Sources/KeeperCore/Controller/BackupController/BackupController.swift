import Foundation

public final class BackupController {
  
  public struct BackupModel {
    public enum BackupState {
      case notBackedUp
      case backedUp(date: String)
    }
    public let backupState: BackupState
  }
  
  public var didUpdateBackupState: (() -> Void)?
  
  private var wallet: Wallet {
    didSet {
      reload()
    }
  }
  
  private let backupStore: BackupStore
  private let walletsStore: WalletsStore
  private let dateFormatter: DateFormatter
  
  init(wallet: Wallet,
       backupStore: BackupStore,
       walletsStore: WalletsStore,
       dateFormatter: DateFormatter) {
    self.wallet = wallet
    self.backupStore = backupStore
    self.walletsStore = walletsStore
    self.dateFormatter = dateFormatter
    
    walletsStore.addObserver(self)
  }
  
  public func reload() {
    didUpdateBackupState?()
  }
  
  public func getBackupModel() -> BackupModel {
    createBackupModel()
  }
  
  public func setDidBackup() throws {
    try backupStore.setDidBackup(for: wallet)
  }
}

private extension BackupController {
  func createBackupModel() -> BackupModel {
    let backupState: BackupModel.BackupState
    if let backupDate = wallet.setupSettings.backupDate {
      dateFormatter.dateFormat = "MMM d yyyy, H:mm"
      backupState = .backedUp(date: dateFormatter.string(from: backupDate))
    } else {
      backupState = .notBackedUp
    }
    return BackupModel(backupState: backupState)
  }
}

extension BackupController: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    switch event {
    case .didUpdateWalletBackupState(let walletId):
      guard let wallet = walletsStore.wallets.first(where: { $0.identity == walletId }) else { return }
      self.wallet = wallet
    default:
      break
    }
  }
}

//extension BackupController: BackupStoreObserver {
//  func didGetBackupStoreEvent(_ event: BackupStoreEvent) {
//    switch event {
//    case .didBackup(let walletId):
//      guard walletId == wallet.identity else { return }
//      didUpdateBackupState?()
//    }
//  }
//}
