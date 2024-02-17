import Foundation

public final class WalletBalanceController {
  
  public var didUpdateBalance: ((WalletBalanceModel) -> Void)?
  public var didUpdateFinishSetup: ((WalletBalanceSetupModel) -> Void)?
  
  public var address: String {
    do {
      return try wallet.address.toShortString(bounceable: false)
    } catch {
      return " "
    }
  }
  
  public var fullAddress: String? {
    try? wallet.address.toString(bounceable: false)
  }

  private var wallet: Wallet
  private let walletsStore: WalletsStore
  private let balanceStore: BalanceStore
  private let ratesStore: RatesStore
  private let currencyStore: CurrencyStore
  private let walletBalanceMapper: WalletBalanceMapper
    
  init(wallet: Wallet,
       walletsStore: WalletsStore,
       balanceStore: BalanceStore,
       ratesStore: RatesStore,
       currencyStore: CurrencyStore,
       walletBalanceMapper: WalletBalanceMapper) {
    self.wallet = wallet
    self.walletsStore = walletsStore
    self.balanceStore = balanceStore
    self.ratesStore = ratesStore
    self.currencyStore = currencyStore
    self.walletBalanceMapper = walletBalanceMapper
    startStoresObservation()
  }

  public func loadBalance() {
    updateFinishSetup()
    updateBalance()
    Task {
      try await self.balanceStore.loadBalance(address: self.wallet.address)
    }
  }
}

private extension WalletBalanceController {
  func didReceiveBalanceUpdateEvent(_ event: BalanceStore.Event) {
    guard let address = try? wallet.address, event.address == address else { return }
    switch event.result {
    case .success:
      updateBalance()
    case .failure(let error):
      // show error
      print(error)
    }
  }
  
  func didReceiveRatesUpdateEvent() {
    updateBalance()
  }
  
  func updateBalance() {
    let currency = currencyStore.getActiveCurrency()
    Task {
      let balanceModel: WalletBalanceModel
      do {
        let walletBalance = try await balanceStore.getBalance(address: try wallet.address)
        let rates = await ratesStore.getRates(jettons: walletBalance.balance.jettonsBalance.map { $0.amount.jettonInfo })
        balanceModel = walletBalanceMapper.mapBalance(
          walletBalance: walletBalance,
          rates: rates,
          currency: currency
        )
      } catch {
        balanceModel = WalletBalanceModel(total: "-", items: [])
      }
      didUpdateBalance?(balanceModel)
    }
  }
  
  func startStoresObservation() {
    currencyStore.addObserver(self)
    walletsStore.addObserver(self)
    Task {
      await balanceStore.addObserver(self)
    }
    Task {
      await ratesStore.addObserver(self)
    }
  }
  
  func updateFinishSetup() {
    let didBackup = wallet.setupSettings.backupDate != nil
    let model = WalletBalanceSetupModel(
      didBackup: didBackup
    )
    didUpdateFinishSetup?(model)
  }
}

extension WalletBalanceController: BalanceStoreObserver {
  func didGetBalanceStoreEvent(_ event: BalanceStore.Event) {
    didReceiveBalanceUpdateEvent(event)
  }
}

extension WalletBalanceController: RatesStoreObserver {
  func didGetRatesStoreEvent(_ event: RatesStore.Event) {
    switch event {
    case .updateRates:
      didReceiveRatesUpdateEvent()
    }
  }
}

extension WalletBalanceController: CurrencyStoreObserver {
  func didGetCurrencyStoreEvent(_ event: CurrencyStoreEvent) {
    updateBalance()
  }
}

extension WalletBalanceController: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    switch event {
    case .didUpdateWalletBackupState(let walletId):
      guard walletId == self.wallet.identity,
            let wallet = walletsStore.wallets.first(where: { $0.identity == walletId }) else { return }
      self.wallet = wallet
      updateFinishSetup()
    default: break
    }
  }
}
