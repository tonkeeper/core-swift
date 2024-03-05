import Foundation

public final class RootController {
  public enum State {
    case onboarding
    case main(wallets: [Wallet], activeWallet: Wallet)
  }

  private let walletsService: WalletsService
  private let remoteConfigurationStore: ConfigurationStore
  private let knownAccountsStore: KnownAccountsStore
  private let deeplinkParser: DeeplinkParser
  
  init(walletsService: WalletsService,
       remoteConfigurationStore: ConfigurationStore,
       knownAccountsStore: KnownAccountsStore,
       deeplinkParser: DeeplinkParser) {
    self.walletsService = walletsService
    self.remoteConfigurationStore = remoteConfigurationStore
    self.knownAccountsStore = knownAccountsStore
    self.deeplinkParser = deeplinkParser
  }
  
  public func getState() -> State {
    do {
      let wallets = try walletsService.getWallets()
      let activeWallet = try walletsService.getActiveWallet()
      return .main(wallets: wallets, activeWallet: activeWallet)
    } catch {
      return .onboarding
    }
  }
  
  public func loadConfiguration() {
    Task {
      try await remoteConfigurationStore.load()
    }
  }
  
  public func loadKnownAccounts() {
    Task {
      try await knownAccountsStore.load()
    }
  }
  
  public func parseDeeplink(string: String?) throws -> Deeplink {
    try deeplinkParser.parse(string: string)
  }
}
