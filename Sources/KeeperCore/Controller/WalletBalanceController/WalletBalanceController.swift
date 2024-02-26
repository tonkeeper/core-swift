import Foundation

public final class WalletBalanceController {
  
  public var didUpdateBalance: (() -> Void)?
  public var didUpdateTotalBalance: (() -> Void)?
  public var didUpdateFinishSetup: ((WalletBalanceSetupModel) -> Void)?
  public var didUpdateBackgroundUpdateState: ((BackgroundUpdateStore.State) -> Void)?
  
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
  
  public var backgroundUpdateState: BackgroundUpdateStore.State {
    get async {
      await backgroundUpdateStore.state
    }
  }
  
  public var walletBalanceModel: WalletBalanceModel {
    get {
      return getWalletBalanceModel()
    }
  }
  
  public var totalBalanceFormatted: String {
    let currency = currencyStore.getActiveCurrency()
    return walletBalanceMapper.mapTotalBalance(totalBalanceStore.getTotalBalance(
      wallet: wallet,
      currency: currency),
      currency: currency
    )
  }

  private var wallet: Wallet
  private let walletsStore: WalletsStore
  private let balanceStore: BalanceStore
  private let totalBalanceStore: TotalBalanceStore
  private let ratesStore: RatesStore
  private let currencyStore: CurrencyStore
  private let securityStore: SecurityStore
  private let setupStore: SetupStore
  private let backgroundUpdateStore: BackgroundUpdateStore
  private let walletBalanceMapper: WalletBalanceMapper
    
  init(wallet: Wallet,
       walletsStore: WalletsStore,
       balanceStore: BalanceStore,
       totalBalanceStore: TotalBalanceStore,
       ratesStore: RatesStore,
       currencyStore: CurrencyStore,
       securityStore: SecurityStore,
       setupStore: SetupStore,
       backgroundUpdateStore: BackgroundUpdateStore,
       walletBalanceMapper: WalletBalanceMapper) {
    self.wallet = wallet
    self.walletsStore = walletsStore
    self.balanceStore = balanceStore
    self.totalBalanceStore = totalBalanceStore
    self.ratesStore = ratesStore
    self.currencyStore = currencyStore
    self.securityStore = securityStore
    self.setupStore = setupStore
    self.backgroundUpdateStore = backgroundUpdateStore
    self.walletBalanceMapper = walletBalanceMapper
    startStoresObservation()
  }

  public func loadBalance() {
    updateFinishSetup()
    updateBalance()
  }
  
  public func finishSetup() {
    try? setupStore.setSetupIsFinished()
  }
  
  public func setIsBiometryEnabled(_ isBiometryEnabled: Bool) -> Bool {
    do {
      try securityStore.setIsBiometryEnabled(isBiometryEnabled)
      return isBiometryEnabled
    } catch {
      return !isBiometryEnabled
    }
  }
}

private extension WalletBalanceController {
  func getWalletBalanceModel() -> WalletBalanceModel {
    let currency = currencyStore.getActiveCurrency()
    let balanceModel: WalletBalanceModel
    do {
      let walletBalance = try balanceStore.getBalance(wallet: wallet)
      let rates = ratesStore.getRates(jettons: walletBalance.balance.jettonsBalance.map { $0.amount.jettonInfo })
      balanceModel = walletBalanceMapper.mapBalance(
        walletBalance: walletBalance,
        rates: rates,
        currency: currency
      )
    } catch {
      balanceModel = WalletBalanceModel(tonItems: [], jettonsItems: [])
    }
    return balanceModel
  }
  
  func didReceiveBalanceUpdateEvent(_ event: BalanceStore.Event) {
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
    didUpdateBalance?()
  }
  
  func startStoresObservation() {
    currencyStore.addObserver(self)
    walletsStore.addObserver(self)
    setupStore.addObserver(self)
    securityStore.addObserver(self)
    totalBalanceStore.addObserver(self)
    Task {
      await balanceStore.addObserver(self)
    }
    Task {
      await ratesStore.addObserver(self)
    }
    Task {
      await backgroundUpdateStore.addObserver(self)
    }
  }
  
  func updateFinishSetup() {
    let didBackup = wallet.setupSettings.backupDate != nil
    let didFinishSetup = setupStore.isSetupFinished
    let isBiometryEnabled = securityStore.isBiometryEnabled
    let isFinishSetupAvailable = didBackup
    
    let model = WalletBalanceSetupModel(
      didBackup: didBackup,
      biometry: WalletBalanceSetupModel.Biometry(
        isBiometryEnabled: isBiometryEnabled,
        isRequired: !didFinishSetup && !isBiometryEnabled
      ),
      isFinishSetupAvailable: isFinishSetupAvailable
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
    case .didUpdateWalletBackupState(let wallet):
      self.wallet = wallet
      updateFinishSetup()
    default:
      break
    }
  }
}

extension WalletBalanceController: SetupStoreObserver {
  func didGetSetupStoreEvent(_ event: SetupStoreEvent) {
    updateFinishSetup()
  }
}

extension WalletBalanceController: SecurityStoreObserver {
  func didGetSecurityStoreEvent(_ event: SecurityStoreEvent) {
    updateFinishSetup()
  }
}

extension WalletBalanceController: BackgroundUpdateStoreObserver {
  public func didGetBackgroundUpdateStoreEvent(_ event: BackgroundUpdateStore.Event) {
    switch event {
    case .didUpdateState(let state):
      didUpdateBackgroundUpdateState?(state)
    case .didReceiveUpdateEvent:
      break
    }
  }
}

extension WalletBalanceController: TotalBalanceStoreObserver {
  func didGetTotalBalanceStoreEvent(_ event: TotalBalanceStore.Event) {
    switch event {
    case .didUpdateTotalBalance(let wallet, _):
      guard wallet == self.wallet else { return }
      didUpdateTotalBalance?()
    }
  }
}
