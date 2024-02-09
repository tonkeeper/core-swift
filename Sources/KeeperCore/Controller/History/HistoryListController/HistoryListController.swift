import Foundation
import TonSwift

public final class HistoryListController {
  
  public enum Event {
    case reset
    case loadingStart
    case noEvents
    case events(sections: [HistoryListSection])
    case paginationStart
    case paginationFailed
  }
  
  public var didSendEvent: ((Event) -> Void)?
  
  private var sections = [HistoryListSection]()
  private var sectionsMap = [Date: Int]()
  
  private var paginator: HistoryListPaginator?
  
  private let paginatorProvider: (Address, ((HistoryListPaginator.Event) -> Void)?) -> HistoryListPaginator
  private let walletsStore: WalletsStore
  private let nftService: NFTService
  private let historyListMapper: HistoryListMapper
  private let dateFormatter: DateFormatter
  
  init(paginatorProvider: @escaping (Address, ((HistoryListPaginator.Event) -> Void)?) -> HistoryListPaginator,
       walletsStore: WalletsStore,
       nftService: NFTService,
       historyListMapper: HistoryListMapper,
       dateFormatter: DateFormatter) {
    self.paginatorProvider = paginatorProvider
    self.walletsStore = walletsStore
    self.nftService = nftService
    self.historyListMapper = historyListMapper
    self.dateFormatter = dateFormatter
    walletsStore.addObserver(self)
  }
  
  public func start() {
    didSendEvent?(.reset)
    sections = []
    sectionsMap = [:]
    Task {
      paginator = try paginatorProvider(walletsStore.activeWallet.address, { [weak self] event in
        self?.handlePaginatorEvent(event)
      })
      try await paginator?.startLoading()
    }
  }
  
  public func loadNext() {
    Task {
      await paginator?.loadNext()
    }
  }
}

private extension HistoryListController {
  func handlePaginatorEvent(_ event: HistoryListPaginator.Event) {
    switch event {
    case .didGetCachedEvents(let events):
      Task {
        await handleLoadedEvents(events)
        sections = []
        sectionsMap = [:]
      }
    case .startLoading:
      didSendEvent?(.loadingStart)
    case .noEvents:
      didSendEvent?(.noEvents)
    case .didLoadEvents(let historyEvents):
      Task {
        await handleLoadedEvents(historyEvents)
      }
    case .startPageLoading:
      didSendEvent?(.paginationStart)
    case .pageLoadingFailed:
      didSendEvent?(.paginationFailed)
    }
  }
  
  func handleLoadedEvents(_ events: AccountEvents) async {
    let nfts = await handleEventsWithNFTs(events: events.events)
    handleEvents(events, andNFTs: nfts)
  }
  
  func handleEventsWithNFTs(events: [AccountEvent]) async -> NFTsCollection {
    let actions = events.flatMap { $0.actions }
    var nftAddressesToLoad = Set<Address>()
    var nfts = [Address: NFT]()
    for action in actions {
        switch action.type {
        case .nftItemTransfer(let nftItemTransfer):
            nftAddressesToLoad.insert(nftItemTransfer.nftAddress)
        case .nftPurchase(let nftPurchase):
            nfts[nftPurchase.nft.address] = nftPurchase.nft
            try? nftService.saveNFT(nft: nftPurchase.nft)
        default: continue
        }
    }
    
    if let loadedNFTs = try? await nftService.loadNFTs(addresses: Array(nftAddressesToLoad)) {
        nfts = loadedNFTs
    }
    
    return NFTsCollection(nfts: nfts)
  }
  
  func handleEvents(_ events: AccountEvents, 
                    andNFTs nfts: NFTsCollection) {
    let calendar = Calendar.current
    
    for event in events.events {
      let eventDate = Date(timeIntervalSince1970: event.timestamp)
      let dateFormat: String
      let dateComponents: DateComponents
      if calendar.isDateInToday(eventDate)
          || calendar.isDateInYesterday(eventDate)
          || calendar.isDate(eventDate, equalTo: Date(), toGranularity: .month) {
        dateComponents = calendar.dateComponents([.year, .month, .day], from: eventDate)
        dateFormat = "HH:mm"
      } else {
        dateComponents = calendar.dateComponents([.year, .month], from: eventDate)
        dateFormat = "MMM d 'at' HH:mm"
      }
      
      guard let sectionDate = calendar.date(from: dateComponents) else { continue }
      
      let eventModel = historyListMapper.mapHistoryEvent(
        event,
        eventDate: eventDate,
        nftsCollection: nfts,
        accountEventRightTopDescriptionProvider: HistoryAccountEventRightTopDescriptionProvider(
          dateFormatter: dateFormatter,
          dateFormat: dateFormat
        )
      )
      
      if let sectionIndex = sectionsMap[sectionDate],
         sections.count > sectionIndex {
        let section = sections[sectionIndex]
        let updatedSectionEvents = section.events + CollectionOfOne(eventModel)
        let updatedSection = HistoryListSection(
          date: section.date,
          title: section.title,
          events: updatedSectionEvents
        )
        sections.remove(at: sectionIndex)
        sections.insert(updatedSection, at: sectionIndex)
      } else {
        let section = HistoryListSection(
          date: sectionDate,
          title: historyListMapper.mapEventsSectionDate(sectionDate),
          events: [eventModel]
        )
        sections = sections + CollectionOfOne(section)
        sectionsMap[sectionDate] = sections.count - 1
      }
    }
    didSendEvent?(.events(sections: sections))
  }
}

extension HistoryListController: WalletsStoreObserver {
  func didGetWalletsStoreEvent(_ event: WalletsStoreEvent) {
    switch event {
    case .didUpdateActiveWallet:
      start()
    default:
      break
    }
  }
}
