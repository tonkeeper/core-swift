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
  private let balanceStore: BalanceStore
  private let ratesStore: RatesStore
  private let currencyStore: CurrencyStore
  private let walletListMapper: WalletListMapper
  
  init(configurator: WalletListControllerConfigurator,
       balanceStore: BalanceStore,
       ratesStore: RatesStore,
       currencyStore: CurrencyStore,
       walletListMapper: WalletListMapper) {
    self.configurator = configurator
    self.balanceStore = balanceStore
    self.ratesStore = ratesStore
    self.currencyStore = currencyStore
    self.walletListMapper = walletListMapper
    
    configurator.didUpdateWallets = { [weak self] in
      guard let self else { return }
      Task {
        self.walletsModels = await self.getWalletsModels()
      }
    }
    
    configurator.didUpdateSelectedWallet = { [weak self] in
      self?.didUpdateActiveWallet?()
    }
      
    Task {
      walletsModels = await getWalletsModels()
    }
    
    Task {
      await balanceStore.addObserver(self)
    }
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
  func getWalletsModels() async -> [WalletModel] {
    var models = [WalletModel]()
    for wallet in configurator.getWallets() {
      await models.append(mapWalletModel(wallet: wallet))
    }
    return models
  }
  
  func getActiveWalletIndex() -> Int? {
    configurator.getSelectedWalletIndex()
  }
  
  func mapWalletModel(wallet: Wallet) async -> WalletModel {
    let balanceString: String
    
    let rates: Rates
    do {
      let balance = try balanceStore.getBalance(address: wallet.address).balance
      rates = ratesStore.getRates(jettons: balance.jettonsBalance.map { $0.amount.jettonInfo })
      balanceString = walletListMapper.mapTotalBalance(balance: balance, rates: rates, currency: currencyStore.getActiveCurrency())
    } catch {
      rates = Rates(ton: [], jettonsRates: [])
      balanceString = "-"
    }
    
    let model = walletListMapper.mapWalletModel(
      wallet: wallet,
      balance: balanceString,
      rates: rates
    )
    return model
  }
}

extension WalletListController: BalanceStoreObserver {
  func didGetBalanceStoreEvent(_ event: BalanceStore.Event) {
    Task {
      walletsModels = await getWalletsModels()
    }
  }
}

extension WalletListController: RatesStoreObserver {
  func didGetRatesStoreEvent(_ event: RatesStore.Event) {
    switch event {
    case .updateRates:
      Task {
        walletsModels = await getWalletsModels()
      }
    }
  }
}

