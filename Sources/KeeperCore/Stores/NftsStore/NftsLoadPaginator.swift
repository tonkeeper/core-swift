import Foundation
import TonSwift

actor NftsLoadPaginator {
  
  enum Event {
    case didLoadNfts([NFT])
  }
  
  enum State {
    case idle
    case isLoading(task: Task<[NFT], Swift.Error>)
  }
  
  var didSendEvent: ((Event) -> Void)?
  
  // MARK: - State
  
  private var state: State = .idle
  private let limit = 100
  private var offset: Int = 0
  private var hasMore = true
  
  // MARK: - Dependencies
  
  private let wallet: Wallet
  private let accountNftsService: AccountNFTService
  
  // MARK: - Init
  
  init(wallet: Wallet,
       accountNftsService: AccountNFTService) {
    self.wallet = wallet
    self.accountNftsService = accountNftsService
  }
  
  // MARK: - Handler
  
  func setDidSendEventHandler(_ handler: ((Event) -> Void)?) {
    self.didSendEvent = handler
  }
  
  // MARK: - Logic
  
  func startPagination() {
    Task {
      offset = 0
      hasMore = true
      
      do {
        let nfts = try await loadNextPage()
        didSendEvent?(.didLoadNfts(nfts))
      } catch {
        didSendEvent?(.didLoadNfts([]))
      }
    }
  }
  
  func loadNextPage() {
    guard hasMore else { return }
    Task {
      switch state {
      case .idle:
        do {
          let nfts = try await loadNextPage()
          didSendEvent?(.didLoadNfts(nfts))
        } catch {
          didSendEvent?(.didLoadNfts([]))
        }
      case .isLoading:
        return
      }
    }
  }
  
  func getNfts() -> [NFT] {
    do {
      return try accountNftsService.getAccountNfts(accountAddress: wallet.address)
    } catch {
      return []
    }
  }
}

private extension NftsLoadPaginator {
  private func loadNextPage() async throws -> [NFT] {
    let task: Task<[NFT], Swift.Error> = Task {
      let nfts = try await accountNftsService.loadAccountNFTs(
        accountAddress: wallet.address,
        collectionAddress: nil,
        limit: limit,
        offset: offset,
        isIndirectOwnership: true
      )
      try Task.checkCancellation()
      if nfts.count < limit {
        hasMore = false
      }
      offset += limit
      return nfts
    }
    state = .isLoading(task: task)
    let nfts = try await task.value
    state = .idle
    return nfts
  }
}
