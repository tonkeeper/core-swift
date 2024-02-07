import Foundation

public final class SettingsController {
  
  public var didUpdateActiveWallet: (() -> Void)?
  public var didUpdateActiveCurrency: (() -> Void)?
  
  public struct WalletModel {
    public let title: String
    public let emoji: String
    public let colorIdentifier: String
  }
  
  private let walletsStore: WalletsStore
  private let currencyStore: CurrencyStore
  private let configurationStore: ConfigurationStore
  
  init(walletsStore: WalletsStore,
       currencyStore: CurrencyStore,
       configurationStore: ConfigurationStore) {
    self.walletsStore = walletsStore
    self.currencyStore = currencyStore
    self.configurationStore = configurationStore
    walletsStore.addObserver(self)
    currencyStore.addObserver(self)
  }
  
  public func activeWallet() -> Wallet {
    walletsStore.activeWallet
  }
  
  public func activeWalletModel() -> WalletModel {
    let wallet = walletsStore.activeWallet
    return WalletModel(
      title: wallet.metaData.label,
      emoji: wallet.metaData.emoji,
      colorIdentifier: wallet.metaData.colorIdentifier
    )
  }
  
  public func activeCurrency() -> Currency {
    currencyStore.getActiveCurrency()
  }
  
  public func getAvailableCurrencies() -> [Currency] {
    Currency.allCases
  }
  
  public func setCurrency(_ currency: Currency) {
    currencyStore.setActiveCurrency(currency)
  }
  
  public var supportURL: URL? {
    get async throws {
      guard let string = try await configurationStore.getConfiguration().directSupportUrl else { return nil }
      return URL(string: string)
    }
  }
  
  public var contactUsURL: URL? {
    get async throws {
      guard let string = try await configurationStore.getConfiguration().supportLink else { return nil }
      return URL(string: string)
    }
  }
  
  public var tonkeeperNewsURL: URL? {
    get async throws {
      guard let string = try await configurationStore.getConfiguration().tonkeeperNewsUrl else { return nil }
      return URL(string: string)
    }
  }
}

extension SettingsController: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    didUpdateActiveWallet?()
  }
}

extension SettingsController: CurrencyStoreObserver {
  func didGetCurrencyStoreEvent(_ event: CurrencyStoreEvent) {
    didUpdateActiveCurrency?()
  }
}
