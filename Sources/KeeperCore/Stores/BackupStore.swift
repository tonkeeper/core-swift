import Foundation

enum BackupStoreEvent {
  case didBackup(wallet: Wallet)
}

protocol BackupStoreObserver: AnyObject {
  func didGetBackupStoreEvent(_ event: BackupStoreEvent)
}

final class BackupStore {
  private let walletService: WalletsService
  
  init(walletService: WalletsService) {
    self.walletService = walletService
  }
  
  func setDidBackup(for wallet: Wallet) throws {
    try walletService.updateWallet(
      wallet: wallet,
      setupSettings: WalletSetupSettings(backupDate: Date())
    )
    notifyObservers(event: .didBackup(wallet: wallet))
  }
  
  private var observers = [BackupStoreObserverWrapper]()
  
  struct BackupStoreObserverWrapper {
    weak var observer: BackupStoreObserver?
  }
  
  func addObserver(_ observer: BackupStoreObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(BackupStoreObserverWrapper(observer: observer))
  }
  
  func removeObserver(_ observer: BackupStoreObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension BackupStore {
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }
  
  func notifyObservers(event: BackupStoreEvent) {
    observers.forEach { $0.observer?.didGetBackupStoreEvent(event) }
  }
}
