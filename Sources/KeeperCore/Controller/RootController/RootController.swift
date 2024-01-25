import Foundation

public final class RootController {
  public enum State {
    case onboarding
    case main(wallets: [Wallet], activeWallet: Wallet)
  }

  private let walletsService: WalletsService
  
  init(walletsService: WalletsService) {
    self.walletsService = walletsService
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
}
