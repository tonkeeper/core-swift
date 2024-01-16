import Foundation

public final class RootController {
  
  public enum State {
    case onboarding
    case main(wallets: [Wallet], activeWallet: Wallet)
  }
  
  public var state: State = .onboarding {
    didSet {
      didUpdateState?(state)
    }
  }
  public var didUpdateState: ((State) -> Void)?

  private let keeperInfoService: KeeperInfoService
  
  init(keeperInfoService: KeeperInfoService) {
    self.keeperInfoService = keeperInfoService
    setupState()
  }
}

private extension RootController {
  func setupState() {
    do {
      let keeperInfo = try keeperInfoService.getKeeperInfo()
      if !keeperInfo.wallets.isEmpty,
      let activeWallet = keeperInfo.wallets.first(where: { $0.identity == keeperInfo.currentWallet }) {
        self.state = .main(wallets: keeperInfo.wallets, activeWallet: activeWallet)
      } else {
        self.state = .onboarding
      }
    } catch {
      self.state = .onboarding
    }
  }
}

extension RootController: WalletListUpdaterObserver {
  func didGetWalletListUpdaterEvent(_ event: WalletListUpdaterEvent) {
    setupState()
  }
}
