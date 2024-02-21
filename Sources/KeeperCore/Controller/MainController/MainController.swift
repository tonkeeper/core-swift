import Foundation
import TonSwift

public final class MainController {
  
  public var didUpdateNftsAvailability: ((Bool) -> Void)?
  
  private let walletsStore: WalletsStore
  private let nftsStoreProvider: (Wallet) -> NftsStore
  private let backgroundUpdateStore: BackgroundUpdateStore
  private let tonConnectService: TonConnectService
  
  private var nftsStore: NftsStore?
  private var nftStateTask: Task<Void, Never>?

  init(walletsStore: WalletsStore, 
       nftsStoreProvider: @escaping (Wallet) -> NftsStore,
       backgroundUpdateStore: BackgroundUpdateStore,
       tonConnectService: TonConnectService) {
    self.walletsStore = walletsStore
    self.nftsStoreProvider = nftsStoreProvider
    self.backgroundUpdateStore = backgroundUpdateStore
    self.tonConnectService = tonConnectService
    
    walletsStore.addObserver(self)
    Task {
      await backgroundUpdateStore.addObserver(self)
    }
  }
  
  public func loadNftsState() {
    nftStateTask?.cancel()
    nftStateTask = nil
    
    nftsStore = nftsStoreProvider(walletsStore.activeWallet)
    Task {
      await nftsStore?.addObserver(self)
      let cachedNfts = (await self.nftsStore?.getNfts()) ?? []
      didUpdateNftsAvailability?(!cachedNfts.isEmpty)
      nftStateTask = Task {
        await nftsStore?.loadInitialNfts()
      }
    }
  }
  
  public func startBackgroundUpdate() {
    Task {
      await backgroundUpdateStore.start(addresses: walletsStore.wallets.compactMap { try? $0.address })
    }
  }
  
  public func stopBackgroundUpdate() {
    Task {
      await backgroundUpdateStore.stop()
    }
  }
  
  public func handleTonConnectDeeplink(_ deeplink: TonConnectDeeplink) async throws -> (TonConnectParameters, TonConnectManifest) {
    try await tonConnectService.loadTonConnectConfiguration(with: deeplink)
  }
}

extension MainController: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    switch event {
    case .didUpdateActiveWallet:
      didUpdateNftsAvailability?(false)
      loadNftsState()
    case .didUpdateWallets:
      startBackgroundUpdate()
    default:
      break
    }
  }
}

extension MainController: NftsStoreObserver {
  func didGetNftsStoreEvent(_ event: NftsStore.Event) {
    switch event {
    case .didUpdateNFTs(let nfts):
      didUpdateNftsAvailability?(!nfts.isEmpty)
    }
  }
}

extension MainController: BackgroundUpdateStoreObserver {
  public func didGetBackgroundUpdateStoreEvent(_ event: BackgroundUpdateStore.Event) {
    switch event {
    case .didReceiveUpdateEvent(let event):
      do {
        guard try event.accountAddress == walletsStore.activeWallet.address else { return }
        loadNftsState()
      } catch {}
    case .didUpdateState:
      break
    }
  }
}
