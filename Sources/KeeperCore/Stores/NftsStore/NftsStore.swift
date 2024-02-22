import Foundation
import TonSwift

protocol NftsStoreObserver: AnyObject {
  func didGetNftsStoreEvent(_ event: NftsStore.Event)
}

actor NftsStore {
  enum Event {
    case didUpdateNFTs([NFT])
  }
  
  private var nfts = [NFT]()

  private let loadPaginator: NftsLoadPaginator
  
  init(loadPaginator: NftsLoadPaginator) {
    self.loadPaginator = loadPaginator
  }
  
  func loadInitialNfts() {
    nfts = []
    Task {
      let handler: (NftsLoadPaginator.Event) -> Void = { [weak self] event in
        guard let self = self else { return }
        switch event {
        case .didLoadNfts(let nfts):
          Task {
            await self.handleLoadedNFTs(nfts)
          }
        }
      }
      await loadPaginator.setDidSendEventHandler(handler)
      await loadPaginator.startPagination()
    }
  }
  
  func loadNext() {
    Task {
      await loadPaginator.loadNextPage()
    }
  }
  
  func getNfts() async -> [NFT] {
    await loadPaginator.getNfts()
  }
  
  struct NftsStoreObserverWrapper {
    weak var observer: NftsStoreObserver?
  }
  
  private var observers = [NftsStoreObserverWrapper]()
  
  func addObserver(_ observer: NftsStoreObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(NftsStoreObserverWrapper(observer: observer))
  }
  
  func removeObserver(_ observer: NftsStoreObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension NftsStore {
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }

  func notifyObservers(event: NftsStore.Event) {
    observers.forEach { $0.observer?.didGetNftsStoreEvent(event) }
  }
  
  func handleLoadedNFTs(_ nfts: [NFT]) {
    self.nfts = nfts
    self.notifyObservers(event: .didUpdateNFTs(self.nfts))
  }
}

