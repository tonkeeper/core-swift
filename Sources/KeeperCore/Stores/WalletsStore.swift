import Foundation
import CoreComponents

enum WalletsStoreEvent {
  case didUpdateWallets
  case didUpdateActiveWallet
  case didUpdateWalletMetaData(walletId: WalletIdentity)
  case didUpdateWalletBackupState(walletId: WalletIdentity)
}

protocol WalletsStoreObserver: AnyObject {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent)
}

final class WalletsStore {
  public private(set) var wallets: [Wallet]
  public private(set) var activeWallet: Wallet
  
  private let walletsService: WalletsService
  private let backupStore: BackupStore
  
  init(wallets: [Wallet],
       activeWallet: Wallet,
       walletsService: WalletsService,
       backupStore: BackupStore) {
    self.wallets = wallets
    self.activeWallet = activeWallet
    self.walletsService = walletsService
    self.backupStore = backupStore
    
    backupStore.addObserver(self)
  }

  private var observers = [WalletsStoreObserverWrapper]()
  
  struct WalletsStoreObserverWrapper {
    weak var observer: WalletsStoreObserver?
  }
  
  func addObserver(_ observer: WalletsStoreObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(WalletsStoreObserverWrapper(observer: observer))
  }
  
  func removeObserver(_ observer: WalletsStoreObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension WalletsStore {
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }
  
  func notifyObservers(event: WalletsStoreEvent) {
    observers.forEach { $0.observer?.didGetWalletsStoreEvent(event) }
  }
}

extension WalletsStore: WalletsStoreUpdateObserver {
  func didGetWalletsStoreUpdateEvent(_ event: WalletsStoreUpdateEvent) {
    switch event {
    case .didMakeWalletActive:
      do {
        self.activeWallet = try walletsService.getActiveWallet()
        notifyObservers(event: .didUpdateActiveWallet)
      } catch {
        print("Log: failed to update WalletsStore after change active wallet, error: \(error)")
      }
    case .didUpdateWallets:
      do {
        let wallets = try walletsService.getWallets()
        let activeWallet = try walletsService.getActiveWallet()
        self.wallets = wallets
        self.activeWallet = activeWallet
        notifyObservers(event: .didUpdateWallets)
      } catch {
        print("Log: failed to update WalletsStore after update wallets, error: \(error)")
      }
    case .didUpdateWallet(let walletId):
      do {
        let wallets = try walletsService.getWallets()
        let activeWallet = try walletsService.getActiveWallet()
        self.wallets = wallets
        self.activeWallet = activeWallet
        notifyObservers(event: .didUpdateWalletMetaData(walletId: walletId))
      } catch {
        print("Log: failed to update WalletsStore after update wallet with \(walletId), error: \(error)")
      }
    }
  }
}

extension WalletsStore: BackupStoreObserver {
  func didGetBackupStoreEvent(_ event: BackupStoreEvent) {
    switch event {
    case .didBackup(let walletId):
      do {
        let wallets = try walletsService.getWallets()
        let activeWallet = try walletsService.getActiveWallet()
        self.wallets = wallets
        self.activeWallet = activeWallet
        notifyObservers(event: .didUpdateWalletBackupState(walletId: walletId))
      } catch {
        print("Log: Failed to update WalletsStore wallet after wallet backup \(walletId), error: \(error)")
      }
    }
  }
}

