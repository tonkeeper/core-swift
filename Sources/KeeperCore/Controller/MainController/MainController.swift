import Foundation
import TonSwift

public final class MainController {
  
  public var didUpdateNftsAvailability: ((Bool) -> Void)?
  
  private let walletsStore: WalletsStore
  private let nftsStoreProvider: (Wallet) -> NftsStore
  
  private var nftsStore: NftsStore?
  private var nftStateTask: Task<Void, Never>?

  init(walletsStore: WalletsStore, nftsStoreProvider: @escaping (Wallet) -> NftsStore) {
    self.walletsStore = walletsStore
    self.nftsStoreProvider = nftsStoreProvider
    
    walletsStore.addObserver(self)
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
}

extension MainController: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    switch event {
    case .didUpdateActiveWallet:
      didUpdateNftsAvailability?(false)
      loadNftsState()
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
