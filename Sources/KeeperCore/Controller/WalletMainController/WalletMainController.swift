import Foundation
import CoreComponents

public final class WalletMainController {
  public var didUpdateActiveWallet: (() -> Void)?
  public var didUpdateActiveWalletMetaData: (() -> Void)?
  
  private let walletsStore: WalletsStore
  private let balanceStore: BalanceStore
  private let ratesStore: RatesStore
  private let backgroundUpdateStore: BackgroundUpdateStore
  private let totalBalanceStore: TotalBalanceStore
  
  init(walletsStore: WalletsStore,
       balanceStore: BalanceStore,
       ratesStore: RatesStore,
       backgroundUpdateStore: BackgroundUpdateStore,
       totalBalanceStore: TotalBalanceStore) {
    self.walletsStore = walletsStore
    self.balanceStore = balanceStore
    self.ratesStore = ratesStore
    self.backgroundUpdateStore = backgroundUpdateStore
    self.totalBalanceStore = totalBalanceStore
    
    self.totalBalanceStore.wallets = walletsStore.wallets
    
    self.walletsStore.addObserver(self)
    Task {
      await balanceStore.addObserver(self)
    }
    Task {
      await backgroundUpdateStore.addObserver(self)
    }
  }
  
  public func getActiveWalletModel() -> WalletModel {
    let activeWallet = walletsStore.activeWallet
    return activeWallet.model
  }
  
  public func getActiveWallet() -> Wallet {
    walletsStore.activeWallet
  }
  
  public func loadBalances() {
    Task {
      await balanceStore.loadBalances(wallets: walletsStore.wallets)
    }
  }
}

private extension WalletMainController {
  func didReceiveBalanceUpdateEvent(_ event: BalanceStore.Event) {
    guard let balance = try? event.result.get() else { return }
    Task {
      await ratesStore.loadRates(
        jettons: balance.balance.jettonsBalance.map { $0.item.jettonInfo },
        wallet: event.wallet
      )
    }
  }
  
  func handleActiveWalletUpdate() {
    didUpdateActiveWallet?()
  }
}

extension WalletMainController: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    switch event {
    case .didAddWallets(let addedWallets):
      Task {
        await balanceStore.loadBalances(wallets: addedWallets)
      }
    case .didUpdateActiveWallet:
      didUpdateActiveWallet?()
    case .didUpdateWalletMetadata(let wallet):
      guard walletsStore.activeWallet.identity == wallet.identity else { return }
      didUpdateActiveWalletMetaData?()
    default:
      break
    }
  }
}

extension WalletMainController: BalanceStoreObserver {
  func didGetBalanceStoreEvent(_ event: BalanceStore.Event) {
    didReceiveBalanceUpdateEvent(event)
  }
}

extension WalletMainController: BackgroundUpdateStoreObserver {
  public func didGetBackgroundUpdateStoreEvent(_ event: BackgroundUpdateStore.Event) {
    switch event {
    case .didUpdateState(let state):
      switch state {
      case .connected:
        loadBalances()
      default: break
      }
    case .didReceiveUpdateEvent(let updateEvent):
      Task {
        guard let wallet = walletsStore.wallets.first(where: { (try? $0.address) == updateEvent.accountAddress }) else { return }
        await balanceStore.loadBalance(wallet: wallet)
      }
    }
  }
}
