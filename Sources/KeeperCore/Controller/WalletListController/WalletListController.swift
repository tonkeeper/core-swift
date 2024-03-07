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
  public var activeWalletIndex: Int? {
    getActiveWalletIndex()
  }
  public var isEditable: Bool {
    configurator.isEditable
  }

  private let configurator: WalletListControllerConfigurator
  private let totalBalanceStore: TotalBalanceStore
  private let ratesStore: RatesStore
  private let currencyStore: CurrencyStore
  private let walletListMapper: WalletListMapper
  
  init(configurator: WalletListControllerConfigurator,
       totalBalanceStore: TotalBalanceStore,
       ratesStore: RatesStore,
       currencyStore: CurrencyStore,
       walletListMapper: WalletListMapper) {
    self.configurator = configurator
    self.totalBalanceStore = totalBalanceStore
    self.ratesStore = ratesStore
    self.currencyStore = currencyStore
    self.walletListMapper = walletListMapper
    
    configurator.didUpdateWallets = { [weak self] in
      guard let self else { return }
        self.walletsModels = self.getWalletsModels()
    }
    
    configurator.didUpdateSelectedWallet = { [weak self] in
      self?.didUpdateActiveWallet?()
    }
    
    totalBalanceStore.addObserver(self)
    
    walletsModels = getWalletsModels()
    
    Task {
      await ratesStore.addObserver(self)
    }
  }
  
  public func setWalletActive(with identifier: String) {
    guard let index = _walletsModels.firstIndex(where: { $0.identifier == identifier }) else { return }
    configurator.selectWallet(at: index)
  }
  
  public func moveWallet(fromIndex: Int, toIndex: Int) {
    let previousModels = _walletsModels
    let model = _walletsModels.remove(at: fromIndex)
    _walletsModels.insert(model, at: toIndex)
    do {
      try configurator.moveWallet(fromIndex: fromIndex, toIndex: toIndex)
    } catch {
      walletsModels = previousModels
    }
  }
}

private extension WalletListController {
  func getWalletsModels() -> [WalletModel] {
    let date = Date()
    var models = [WalletModel]()
    for wallet in configurator.getWallets() {
      models.append(mapWalletModel(wallet: wallet))
    }
    return models
  }
  
  func getActiveWalletIndex() -> Int? {
    configurator.getSelectedWalletIndex()
  }
  
  func mapWalletModel(wallet: Wallet) -> WalletModel {
    let totalBalance = totalBalanceStore.getTotalBalance(wallet: wallet, currency: .USD)
    let balanceString = walletListMapper.mapTotalBalance(totalBalance, currency: .USD)
    let model = walletListMapper.mapWalletModel(
      wallet: wallet,
      balance: balanceString
    )
    return model
  }
}

extension WalletListController: RatesStoreObserver {
  func didGetRatesStoreEvent(_ event: RatesStore.Event) {
    switch event {
    case .updateRates:
      Task {
        walletsModels = getWalletsModels()
      }
    }
  }
}

extension WalletListController: TotalBalanceStoreObserver {
  func didGetTotalBalanceStoreEvent(_ event: TotalBalanceStore.Event) {
    switch event {
    case .didUpdateTotalBalance:
      Task {
        walletsModels = getWalletsModels()
      }
    }
  }
}

