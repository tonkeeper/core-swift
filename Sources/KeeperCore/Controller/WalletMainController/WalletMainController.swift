import Foundation
import CoreComponents

public final class WalletMainController {
  public var didUpdateActiveWallet: (() -> Void)?
  public var didUpdateActiveWalletMetaData: (() -> Void)?
  
  public struct WalletModel {
    public let name: String
    public let colorIdentifier: String
  }
  
  private let walletsStore: WalletsStore
  private let balanceStore: BalanceStore
  private let ratesStore: RatesStore
  
  init(walletsStore: WalletsStore,
       balanceStore: BalanceStore,
       ratesStore: RatesStore) {
    self.walletsStore = walletsStore
    self.balanceStore = balanceStore
    self.ratesStore = ratesStore
    
    self.walletsStore.addObserver(self)
    Task {
      await balanceStore.addObserver(self)
    }
  }
  
  public func getActiveWalletModel() -> WalletModel {
    let activeWallet = walletsStore.activeWallet
    let model = WalletModel(name: activeWallet.metaData.emoji + " " + activeWallet.metaData.label,
                            colorIdentifier: activeWallet.metaData.colorIdentifier)
    return model
  }
  
  public func getActiveWallet() -> Wallet {
    walletsStore.activeWallet
  }
  
  public func loadBalances() {
    Task {
      let addresses = self.walletsStore.wallets.compactMap { try? $0.address }
      await self.balanceStore.loadBalances(addresses: addresses)
    }
  }
}

private extension WalletMainController {
  func didReceiveBalanceUpdateEvent(_ event: BalanceStore.Event) {
    guard let balance = try? event.result.get() else { return }
    Task {
      await ratesStore.loadRates(jettons: balance.balance.jettonsBalance.map { $0.amount.jettonInfo })
    }
  }
  
  func handleActiveWalletUpdate() {
    didUpdateActiveWallet?()
  }
}

extension WalletMainController: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    switch event {
    case .didUpdateActiveWallet:
      handleActiveWalletUpdate()
    case .didUpdateWalletMetaData(let walletId):
      if walletsStore.activeWallet.identity == walletId {
        didUpdateActiveWalletMetaData?()
      }
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
