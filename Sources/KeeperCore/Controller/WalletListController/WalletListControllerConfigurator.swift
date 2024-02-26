import Foundation

protocol WalletListControllerConfigurator: AnyObject {
  var didUpdateWallets: (() -> Void)? { get set }
  var didUpdateSelectedWallet: (() -> Void)? { get set }
  
  var isEditable: Bool { get }
  
  func getWallets() -> [Wallet]
  func getSelectedWalletIndex() -> Int?
  func selectWallet(at index: Int)
  func moveWallet(fromIndex: Int, toIndex: Int) throws
}

final class WalletStoreWalletListControllerConfigurator: WalletListControllerConfigurator {
  
  var didUpdateWallets: (() -> Void)?
  var didUpdateSelectedWallet: (() -> Void)?
  
  var isEditable: Bool {
    walletsStore.wallets.count > 1
  }
  
  func getWallets() -> [Wallet] {
    walletsStore.wallets
  }
  
  func getSelectedWalletIndex() -> Int? {
    walletsStore.wallets.firstIndex(where: { $0.identity == walletsStore.activeWallet.identity })
  }
  
  func selectWallet(at index: Int) {
    guard index < walletsStore.wallets.count else { return }
    do {
      try walletsStoreUpdate.makeWalletActive(walletsStore.wallets[index])
    } catch {
      didUpdateSelectedWallet?()
    }
  }
  
  func moveWallet(fromIndex: Int, toIndex: Int) throws {
    try walletsStoreUpdate.moveWallet(fromIndex: fromIndex, toIndex: toIndex)
  }
  
  private let walletsStore: WalletsStore
  private let walletsStoreUpdate: WalletsStoreUpdate
  
  init(walletsStore: WalletsStore, walletsStoreUpdate: WalletsStoreUpdate) {
    self.walletsStore = walletsStore
    self.walletsStoreUpdate = walletsStoreUpdate
    
    walletsStore.addObserver(self)
  }
}

extension WalletStoreWalletListControllerConfigurator: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    switch event {
    case .didUpdateActiveWallet:
      didUpdateSelectedWallet?()
    case .didUpdateWalletsOrder:
      didUpdateWallets?()
    case .didAddWallets:
      didUpdateWallets?()
    default:
      break
    }
  }
}

final class WalletSelectWalletListControllerConfigurator: WalletListControllerConfigurator {
  
  var didSelectWallet: ((Wallet) -> Void)?
  
  var didUpdateWallets: (() -> Void)?
  var didUpdateSelectedWallet: (() -> Void)?
  
  var isEditable: Bool {
    false
  }
  
  func getWallets() -> [Wallet] {
    walletsStore.wallets
  }
  
  func getSelectedWalletIndex() -> Int? {
    walletsStore.wallets.firstIndex(where: { $0.identity == selectedWallet.identity })
  }
  
  func selectWallet(at index: Int) {
    guard index < walletsStore.wallets.count else { return }
    let selectedWallet = walletsStore.wallets[index]
    didSelectWallet?(selectedWallet)
  }
  
  func moveWallet(fromIndex: Int, toIndex: Int) throws {}
  
  private let selectedWallet: Wallet
  private let walletsStore: WalletsStore
  
  init(selectedWallet: Wallet, walletsStore: WalletsStore) {
    self.selectedWallet = selectedWallet
    self.walletsStore = walletsStore
    
    walletsStore.addObserver(self)
  }
}

extension WalletSelectWalletListControllerConfigurator: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    switch event {
    case .didAddWallets:
      didUpdateWallets?()
    case .didUpdateWalletsOrder:
      didUpdateWallets?()
    case .didUpdateActiveWallet:
      didUpdateSelectedWallet?()
    default:
      break
    }
  }
}
