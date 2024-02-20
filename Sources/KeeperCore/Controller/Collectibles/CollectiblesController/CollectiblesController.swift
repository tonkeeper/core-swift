import Foundation

public final class CollectiblesController {
  
  public var didUpdateIsConnecting: ((Bool) -> Void)?

  private let walletsStore: WalletsStore
  private let backgroundUpdateStore: BackgroundUpdateStore
  
  init(walletsStore: WalletsStore,
       backgroundUpdateStore: BackgroundUpdateStore) {
    self.walletsStore = walletsStore
    self.backgroundUpdateStore = backgroundUpdateStore
    Task {
      await backgroundUpdateStore.addObserver(self)
    }
  }
  
  public var wallet: Wallet {
    walletsStore.activeWallet
  }
  
  public func updateConnectingState() {
    Task {
      let state = await backgroundUpdateStore.state
      handleBackgroundUpdateState(state)
    }
  }
}

private extension CollectiblesController {
  func handleBackgroundUpdateState(_ state: BackgroundUpdateStore.State) {
    let isConnecting: Bool
    switch state {
    case .connecting:
      isConnecting = true
    case .connected:
      isConnecting = false
    case .disconnected:
      isConnecting = true
    case .noConnection:
      isConnecting = false
    }
    didUpdateIsConnecting?(isConnecting)
  }
}

extension CollectiblesController: BackgroundUpdateStoreObserver {
  public func didGetBackgroundUpdateStoreEvent(_ event: BackgroundUpdateStore.Event) {
    switch event {
    case .didUpdateState(let state):
      handleBackgroundUpdateState(state)
    case .didReceiveUpdateEvent:
      break
    }
  }
}
