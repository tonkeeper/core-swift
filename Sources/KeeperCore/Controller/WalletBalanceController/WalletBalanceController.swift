import Foundation

public final class WalletBalanceController {
  
  public var didUpdateBalance: (() -> Void)?
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
    get async {
      return await getWalletBalanceModel()
    }
  }

  private var wallet: Wallet
  private let walletsStore: WalletsStore
  private let balanceStore: BalanceStore
  private let ratesStore: RatesStore
  private let currencyStore: CurrencyStore
  private let securityStore: SecurityStore
  private let setupStore: SetupStore
  private let backgroundUpdateStore: BackgroundUpdateStore
  private let walletBalanceMapper: WalletBalanceMapper
    
  init(wallet: Wallet,
       walletsStore: WalletsStore,
       balanceStore: BalanceStore,
       ratesStore: RatesStore,
       currencyStore: CurrencyStore,
       securityStore: SecurityStore,
       setupStore: SetupStore,
       backgroundUpdateStore: BackgroundUpdateStore,
       walletBalanceMapper: WalletBalanceMapper) {
    self.wallet = wallet
    self.walletsStore = walletsStore
    self.balanceStore = balanceStore
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
    Task {
      try await self.balanceStore.loadBalance(address: self.wallet.address)
    }
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
  func getWalletBalanceModel() async -> WalletBalanceModel {
    let currency = currencyStore.getActiveCurrency()
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
    return balanceModel
  }
  
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
    didUpdateBalance?()
  }
  
  func startStoresObservation() {
    currencyStore.addObserver(self)
    walletsStore.addObserver(self)
    setupStore.addObserver(self)
    securityStore.addObserver(self)
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
    case .didUpdateWalletBackupState(let walletId):
      guard walletId == self.wallet.identity,
            let wallet = walletsStore.wallets.first(where: { $0.identity == walletId }) else { return }
      self.wallet = wallet
      updateFinishSetup()
    default: break
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
