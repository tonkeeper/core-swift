import Foundation

public final class MainAssembly {
  
  public struct Dependencies {
    let wallets: [Wallet]
    let activeWallet: Wallet
    
    public init(wallets: [Wallet], activeWallet: Wallet) {
      self.wallets = wallets
      self.activeWallet = activeWallet
    }
  }
  
  let walletAssembly: WalletAssembly
  public let walletUpdateAssembly: WalletsUpdateAssembly
  let servicesAssembly: ServicesAssembly
  let storesAssembly: StoresAssembly
  let formattersAssembly: FormattersAssembly
  
  init(walletAssembly: WalletAssembly,
       walletUpdateAssembly: WalletsUpdateAssembly,
       servicesAssembly: ServicesAssembly,
       storesAssembly: StoresAssembly,
       formattersAssembly: FormattersAssembly) {
    self.walletAssembly = walletAssembly
    self.walletUpdateAssembly = walletUpdateAssembly
    self.servicesAssembly = servicesAssembly
    self.storesAssembly = storesAssembly
    self.formattersAssembly = formattersAssembly
  }
  
  public func walletMainController() -> WalletMainController {
    WalletMainController(
      walletsStore: walletAssembly.walletStore,
      balanceStore: storesAssembly.balanceStore,
      ratesStore: storesAssembly.ratesStore
    )
  }
  
  public func walletListController() -> WalletListController {
    WalletListController(
      walletsStore: walletAssembly.walletStore,
      walletsStoreUpdate: walletUpdateAssembly.walletsStoreUpdate,
      balanceStore: storesAssembly.balanceStore,
      ratesStore: storesAssembly.ratesStore,
      walletListMapper: walletListMapper
    )
  }
  
  public func walletBalanceController(wallet: Wallet) -> WalletBalanceController {
    WalletBalanceController(
      wallet: wallet,
      balanceStore: storesAssembly.balanceStore,
      ratesStore: storesAssembly.ratesStore,
      walletBalanceMapper: walletBalanceMapper
    )
  }
}

private extension MainAssembly {
  var walletBalanceMapper: WalletBalanceMapper {
    WalletBalanceMapper(
      amountFormatter: formattersAssembly.amountFormatter,
      decimalAmountFormatter: formattersAssembly.decimalAmountFormatter,
      rateConverter: RateConverter())
  }
  
  var walletListMapper: WalletListMapper {
    WalletListMapper(
      amountFormatter: formattersAssembly.amountFormatter,
      decimalAmountFormatter: formattersAssembly.decimalAmountFormatter,
      rateConverter: RateConverter()
    )
  }
}
