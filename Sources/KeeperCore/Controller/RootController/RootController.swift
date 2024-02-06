import Foundation

public final class RootController {
  public enum State {
    case onboarding
    case main(wallets: [Wallet], activeWallet: Wallet)
  }

  private let walletsService: WalletsService
  private let remoteConfigurationStore: ConfigurationStore
  
  init(walletsService: WalletsService,
       remoteConfigurationStore: ConfigurationStore) {
    self.walletsService = walletsService
    self.remoteConfigurationStore = remoteConfigurationStore
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
}
