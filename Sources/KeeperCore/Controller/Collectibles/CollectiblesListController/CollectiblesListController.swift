import Foundation
import TonSwift

public actor CollectiblesListController {
  
  public struct NFTModel {
    public let address: Address
    public let name: String?
    public let collectionName: String?
    public let imageUrl: URL?
  }
  
  public enum Event {
    case updateNFTs(nfts: [NFTModel])
  }
  
  public var didSendEvent: ((Event) -> Void)?
  
  // MARK: - State
  
  private var models = [NFTModel]()
  
  // MARK: - Dependencies
  
  private let nftsStore: NftsStore
  
  // MARK: - Init
  
  init(nftsStore: NftsStore) {
    self.nftsStore = nftsStore
  }
  
  // MARK: - Logic
  
  public func start() {
    Task {
      await nftsStore.addObserver(self)
      
      let cached = await self.nftsStore.getNfts()
      let models = self.mapNfts(cached)
      self.didSendEvent?(.updateNFTs(nfts: models))
      
      await nftsStore.loadInitialNfts()
    }
  }
  
  public func loadNext() {
    Task {
      await nftsStore.loadNext()
    }
  }
  
  public func setDidSendEventHandler(_ didSendEvent: ((Event) -> Void)?) {
    self.didSendEvent = didSendEvent
  }
}

private extension CollectiblesListController {
  nonisolated
  func mapNfts(_ nfts: [NFT]) -> [NFTModel] {
    nfts.map { mapNft($0) }
  }
  
  nonisolated
  func mapNft(_ nft: NFT) -> NFTModel {
    let name = nft.name ?? nft.address.toString(bounceable: true)
    let collectionName: String?
    if let collection = nft.collection {
      collectionName = (collection.name == nil || collection.name?.isEmpty == true) ? "Unnamed collection" : collection.name
    } else {
      collectionName = "Unnamed collection"
    }

    return NFTModel(address: nft.address,
                    name: name,
                    collectionName: collectionName,
                    imageUrl: nft.preview.size500)
  }
  
  func handleUpdatedNfts(_ nfts: [NFT]) {
    let models = self.mapNfts(nfts)
    self.models = models
    self.didSendEvent?(.updateNFTs(nfts: self.models))
  }
}

extension CollectiblesListController: NftsStoreObserver {
  nonisolated func didGetNftsStoreEvent(_ event: NftsStore.Event) {
    switch event {
    case .didUpdateNFTs(let nfts):
      Task {
        await handleUpdatedNfts(nfts)
      }
    }
  }
}
