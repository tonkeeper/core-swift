import Foundation

public final class TokenDetailsController {
  
  public var didUpdateTokenModel: ((TokenModel) -> Void)?
  
  public struct TokenModel {
    public enum Image {
      case ton
      case url(URL?)
    }
    public let tokenTitle: String
    public let tokenSubtitle: String?
    public let image: Image
    public let tokenAmount: String
    public let convertedAmount: String?
    public let buttons: [IconButton]
  }
  
  private let configurator: TokenDetailsControllerConfigurator
  private let walletsStore: WalletsStore
  private let balanceStore: BalanceStore
  private let ratesStore: RatesStore
  private let currencyStore: CurrencyStore
  
  init(configurator: TokenDetailsControllerConfigurator,
       walletsStore: WalletsStore,
       balanceStore: BalanceStore,
       ratesStore: RatesStore,
       currencyStore: CurrencyStore) {
    self.configurator = configurator
    self.walletsStore = walletsStore
    self.balanceStore = balanceStore
    self.ratesStore = ratesStore
    self.currencyStore = currencyStore
    Task {
      await balanceStore.addObserver(self)
    }
    Task {
      await ratesStore.addObserver(self)
    }
  }
  
  public func reloadTokenModel() {
    let wallet = walletsStore.activeWallet
    Task {
      let address = try wallet.address
      let balance: Balance
      do {
        balance = try await balanceStore.getBalance(address: address).balance
      } catch {
        balance = Balance(
          tonBalance: TonBalance(amount: 0),
          jettonsBalance: []
        )
      }
      let rates = await ratesStore.getRates(jettons: balance.jettonsBalance.map { $0.amount.jettonInfo })
      let model = configurator.getTokenModel(balance: balance, rates: rates, currency: currencyStore.getActiveCurrency())
      didUpdateTokenModel?(model)
    }
  }
}

extension TokenDetailsController: BalanceStoreObserver {
  func didGetBalanceStoreEvent(_ event: BalanceStore.Event) {
    reloadTokenModel()
  }
}

extension TokenDetailsController: RatesStoreObserver {
  func didGetRatesStoreEvent(_ event: RatesStore.Event) {
    reloadTokenModel()
  }
}
