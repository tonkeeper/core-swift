import Foundation
import TonSwift

public final class MainController {
  
  public var didUpdateNftsAvailability: ((Bool) -> Void)?
  public var didReceiveTonConnectRequest: ((TonConnect.AppRequest, Wallet, TonConnectApp) -> Void)?
  
  private let walletsStore: WalletsStore
  private let nftsStoreProvider: (Wallet) -> NftsStore
  private let backgroundUpdateStore: BackgroundUpdateStore
  private let tonConnectEventsStore: TonConnectEventsStore
  private let tonConnectService: TonConnectService
  private let deeplinkParser: DeeplinkParser
  
  private var nftsStore: NftsStore?
  private var nftStateTask: Task<Void, Never>?

  init(walletsStore: WalletsStore, 
       nftsStoreProvider: @escaping (Wallet) -> NftsStore,
       backgroundUpdateStore: BackgroundUpdateStore,
       tonConnectEventsStore: TonConnectEventsStore,
       tonConnectService: TonConnectService,
       deeplinkParser: DeeplinkParser) {
    self.walletsStore = walletsStore
    self.nftsStoreProvider = nftsStoreProvider
    self.backgroundUpdateStore = backgroundUpdateStore
    self.tonConnectEventsStore = tonConnectEventsStore
    self.tonConnectService = tonConnectService
    self.deeplinkParser = deeplinkParser
    
    walletsStore.addObserver(self)
    Task {
      await backgroundUpdateStore.addObserver(self)
    }
    Task {
      await tonConnectEventsStore.addObserver(self)
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
    Task {
      await tonConnectEventsStore.start()
    }
  }
  
  public func stopBackgroundUpdate() {
    Task {
      await backgroundUpdateStore.stop()
    }
    Task {
      await tonConnectEventsStore.stop()
    }
  }
  
  public func handleTonConnectDeeplink(_ deeplink: TonConnectDeeplink) async throws -> (TonConnectParameters, TonConnectManifest) {
    try await tonConnectService.loadTonConnectConfiguration(with: deeplink)
  }
  
  public func parseDeeplink(deeplink: String?) throws -> Deeplink {
    try deeplinkParser.parse(string: deeplink)
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

extension MainController: TonConnectEventsStoreObserver {
  public func didGetTonConnectEventsStoreEvent(_ event: TonConnectEventsStore.Event) {
    switch event {
    case .request(let request, let wallet, let app):
      Task { @MainActor in
        didReceiveTonConnectRequest?(request, wallet, app)
      }
    }
  }
}
