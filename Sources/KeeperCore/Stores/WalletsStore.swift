import Foundation
import CoreComponents

enum WalletsStoreEvent {
  case didAddWallets([Wallet])
  case didUpdateActiveWallet
  case didUpdateWalletMetadata(Wallet)
  case didUpdateWalletsOrder
  case didUpdateWalletBackupState(Wallet)
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
    case .didAddWallets(let addedWallets):
      do {
        let wallets = try walletsService.getWallets()
        let activeWallet = try walletsService.getActiveWallet()
        self.wallets = wallets
        self.activeWallet = activeWallet
        notifyObservers(event: .didAddWallets(addedWallets))
      } catch {
        print("Log: failed to update WalletsStore after add wallets: \(addedWallets), error: \(error)")
      }
    case .didUpdateActiveWallet:
      do {
        self.activeWallet = try walletsService.getActiveWallet()
        notifyObservers(event: .didUpdateActiveWallet)
      } catch {
        print("Log: failed to update WalletsStore after active wallet update, error: \(error)")
      }
    case .didUpdateWalletMetadata(let wallet, _):
      do {
        let wallets = try walletsService.getWallets()
        let activeWallet = try walletsService.getActiveWallet()
        self.wallets = wallets
        self.activeWallet = activeWallet
        guard let updatedWallet = self.wallets.first(where: { $0.identity == wallet.identity }) else {
          print("Log: Failed to get updated wallet after update wallets metadata \(wallet)")
          return
        }
        notifyObservers(event: .didUpdateWalletMetadata(updatedWallet))
      } catch {
        print("Log: failed to update WalletsStore after update wallets metadata \(wallet), error: \(error)")
      }
    case .didUpdateWalletsOrder:
      do {
        let wallets = try walletsService.getWallets()
        let activeWallet = try walletsService.getActiveWallet()
        self.wallets = wallets
        self.activeWallet = activeWallet
        notifyObservers(event: .didUpdateWalletsOrder)
      } catch {
        print("Log: failed to update WalletsStore after update wallets order, error: \(error)")
      }
    }
  }
}

extension WalletsStore: BackupStoreObserver {
  func didGetBackupStoreEvent(_ event: BackupStoreEvent) {
    switch event {
    case .didBackup(let wallet):
      do {
        let wallets = try walletsService.getWallets()
        let activeWallet = try walletsService.getActiveWallet()
        self.wallets = wallets
        self.activeWallet = activeWallet
        guard let updatedWallet = self.wallets.first(where: { $0.identity == wallet.identity }) else {
          print("Log: Failed to get updated wallet after wallet backup \(wallet)")
          return
        }
        notifyObservers(event: .didUpdateWalletBackupState(updatedWallet))
      } catch {
        print("Log: Failed to update WalletsStore wallet after wallet backup \(wallet), error: \(error)")
      }
    }
  }
}

