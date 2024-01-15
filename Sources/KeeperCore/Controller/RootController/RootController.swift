import Foundation

public final class RootController {
  
  public enum State {
    case onboarding
    case main
  }
  
  public var state: State = .onboarding {
    didSet {
      didUpdateState?(state)
    }
  }
  public var didUpdateState: ((State) -> Void)?

  private let walletListProvider: WalletListProvider
  
  init(walletListProvider: WalletListProvider) {
    self.walletListProvider = walletListProvider
    setupState()
    walletListProvider.addObserver(self)
  }
}

extension RootController: WalletListProviderObserver {
  func setupState() {
    let hasWallets = (try? !walletListProvider.wallets.isEmpty) ?? false
    self.state = hasWallets ? .main : .onboarding
  }
  
  func didGetWalletListProviderEvent(_ event: WalletListProviderEvent) {
    setupState()
  }
}
