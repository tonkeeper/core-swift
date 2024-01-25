import Foundation
import CoreComponents

public final class WalletListController {
  
  public struct WalletModel: Equatable {
    public let identifier: String
    public let name: String
    public let tag: String?
    public let emoji: String
    public let colorIdentifier: String
    public let balance: String
  }
  
  public var didUpdateWallets: (() -> Void)?
  public var didUpdateActiveWallet: (() -> Void)?
  
  private var _walletsModels = [WalletModel]()
  public private(set) var walletsModels: [WalletModel] {
    get { _walletsModels }
    set {
      guard _walletsModels != newValue else { return }
      _walletsModels = newValue
      didUpdateWallets?()
    }
  }
  public var activeWalletIndex: Int {
    getActiveWalletIndex()
  }

  private let walletsStore: WalletsStore
  private let walletsStoreUpdate: WalletsStoreUpdate
  
  init(walletsStore: WalletsStore,
       walletsStoreUpdate: WalletsStoreUpdate) {
    self.walletsStore = walletsStore
    self.walletsStoreUpdate = walletsStoreUpdate
      
    walletsModels = getWalletsModels()
    
    walletsStore.addObserver(self)
  }
  
  public func setWalletActive(with identifier: String) {
    guard let index = _walletsModels.firstIndex(where: { $0.identifier == identifier }) else { return }
    do {
      try walletsStoreUpdate.makeWalletActive(walletsStore.wallets[index])
    } catch {
      didUpdateActiveWallet?()
    }
  }
  
  public func moveWallet(fromIndex: Int, toIndex: Int) {
    let previousModels = _walletsModels
    let model = _walletsModels.remove(at: fromIndex)
    _walletsModels.insert(model, at: toIndex)
    do {
      try walletsStoreUpdate.moveWallet(fromIndex: fromIndex, toIndex: toIndex)
    } catch {
      walletsModels = previousModels
    }
  }
}

private extension WalletListController {
  func getWalletsModels() -> [WalletModel] {
    walletsStore.wallets.map { mapWalletModel(wallet: $0) }
  }
  
  func getActiveWalletIndex() -> Int {
    walletsStore.wallets.firstIndex(where: { $0.identity == walletsStore.activeWallet.identity }) ?? 0
  }
  
  func mapWalletModel(wallet: Wallet) -> WalletModel {
    let identifier = (try? wallet.identity.id().string) ?? UUID().uuidString
    let name = {
      wallet.metaData.label.isEmpty ? "Wallet" : wallet.metaData.label
    }()
    let tag: String? = {
      if wallet.isRegular {
        switch wallet.isTestnet {
        case true: return "TESTNET"
        case false: return nil
        }
      }
      if wallet.isWatchonly {
       return "WATCH ONLY"
      }
      if wallet.isExternal {
        return "EXTERNAL"
      }
      return nil
    }()
    let emoji: String = {
      wallet.metaData.emoji.isEmpty ? "😀" : wallet.metaData.emoji
    }()
    let colorIdentifier: String = {
      wallet.metaData.colorIdentifier.isEmpty ? "Color1" : wallet.metaData.colorIdentifier
    }()
    
    return WalletModel(
      identifier: identifier,
      name: name,
      tag: tag,
      emoji: emoji,
      colorIdentifier: colorIdentifier,
      balance: "0 TON"
    )
  }
}

extension WalletListController: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    switch event {
    case .didUpdateWallets:
      walletsModels = getWalletsModels()
    case .didUpdateActiveWallet:
      didUpdateActiveWallet?()
    }
  }
}
