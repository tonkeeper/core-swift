//
//  ActivityListController.swift
//  
//
//  Created by Grigory on 3.8.23..
//

import Foundation
import TonSwift

public actor ActivityListController {
    public typealias Stream = AsyncStream<Event>
    
    public enum Event {
        case startLoading
        case updateEvents(_ eventsSections: [String: ActivityEventViewModel])
        case startPagination
        case stopPagination
        case paginationFailed
    }

    public enum Error: Swift.Error {
        case noCollectible(sectionIndex: Int, eventIndex: Int, actionIndex: Int)
    }
    
    public struct EventsSection {
        public let date: Date
        public let title: String?
        public var eventsIds: [String]
    }
    
    // MARK: - Dependencies
    
    private let activityListLoader: ActivityListLoader
    private let collectiblesService: CollectiblesService
    private let walletProvider: WalletProvider
    private let contractBuilder: WalletContractBuilder
    private let activityEventMapper: ActivityEventMapper
    private let transactionsUpdatePublishService: TransactionsUpdateService
    
    // MARK: - State
    
    public private(set) var isLoading = false
    public var hasMore: Bool {
        nextFrom != 0
    }
    
    private let limit: Int = 25
    private var nextFrom: Int64?
    private var loadEventsTask: Task<(ActivityEvents, Collectibles), Error>?
    
    public private(set) var eventsSections = [EventsSection]()
    private var eventsSectionIndexTable = [Date: Int]()
    private var events = [String: ActivityEvent]()
    
    private var streamContinuation: Stream.Continuation?

    init(activityListLoader: ActivityListLoader,
         collectiblesService: CollectiblesService,
         walletProvider: WalletProvider,
         contractBuilder: WalletContractBuilder,
         activityEventMapper: ActivityEventMapper,
         transactionsUpdatePublishService: TransactionsUpdateService) {
        self.activityListLoader = activityListLoader
        self.collectiblesService = collectiblesService
        self.walletProvider = walletProvider
        self.contractBuilder = contractBuilder
        self.activityEventMapper = activityEventMapper
        self.transactionsUpdatePublishService = transactionsUpdatePublishService
    }
    
    deinit {
        streamContinuation?.finish()
        streamContinuation = nil
    }
    
    public func start() {
        reset()
        Task {
            streamContinuation?.yield(.startLoading)
            defer {
                isLoading = false
            }
            isLoading = true
            do {
                let sections = try await loadNextEvents()
                streamContinuation?.yield(.updateEvents(sections))
            } catch {
                streamContinuation?.yield(.updateEvents([:]))
            }
            for try await transaction in await transactionsUpdatePublishService.getEventStream() {
                let event = try await activityListLoader.loadEvent(address: try getAddress(), eventId: transaction.txHash)
                let collectibles = await handleEventsWithNFTs(events: [event])
                let sections = handleLoadedEvents(loadedEvents: [event], collectibles: collectibles)
                streamContinuation?.yield(.updateEvents(sections))
            }
        }
    }
    
    public func fetchNext() {
        streamContinuation?.yield(.startPagination)
        Task {
            do {
                let sections = try await loadNextEvents()
                streamContinuation?.yield(.updateEvents(sections))
                streamContinuation?.yield(.stopPagination)
            } catch {
                streamContinuation?.yield(.stopPagination)
                streamContinuation?.yield(.paginationFailed)
            }
        }
    }
    
    public func eventsStream() -> Stream {
        return Stream { continuation in
            streamContinuation = continuation
            continuation.onTermination = { [weak self] termination in
                guard let self = self else { return }
                Task { await self.resetContinuation() }
            }
        }
    }
    
    public func getCollectibleAddress(sectionIndex: Int,
                                      eventIndex: Int,
                                      actionIndex: Int) throws -> Address {
        let eventId = eventsSections[sectionIndex].eventsIds[eventIndex]
        guard let event = events[eventId] else {
            throw Error.noCollectible(
                sectionIndex: sectionIndex,
                eventIndex: eventIndex,
                actionIndex: actionIndex
            )
        }
        
        switch event.actions[actionIndex].type {
        case .nftPurchase(let nftPurchase):
            return nftPurchase.collectible.address
        case .nftItemTransfer(let nftTransfer):
            return nftTransfer.nftAddress
        default:
            throw Error.noCollectible(
                sectionIndex: sectionIndex,
                eventIndex: eventIndex,
                actionIndex: actionIndex
            )
        }
    }
}

private extension ActivityListController {
    func reset() {
        loadEventsTask?.cancel()
        loadEventsTask = nil
        isLoading = false
        nextFrom = nil
        eventsSections = []
        eventsSectionIndexTable = [:]
        events = [:]
    }
    
    func loadNextEvents() async throws -> [String: ActivityEventViewModel] {
        loadEventsTask?.cancel()
        let task = Task {
            defer {
                isLoading = false
            }
            isLoading = true
            let loadedEvents = try await activityListLoader.loadEvents(
                address: try getAddress(),
                beforeLt: nextFrom,
                limit: limit
            )
            try Task.checkCancellation()
            let collectibles = await handleEventsWithNFTs(events: loadedEvents.events)
            try Task.checkCancellation()
            self.nextFrom = loadedEvents.events.count < limit ? 0 : loadedEvents.nextFrom
            return (loadedEvents, collectibles)
        }
        let taskValue = try await task.value
        if taskValue.0.events.isEmpty && taskValue.0.nextFrom != 0 {
            return try await loadNextEvents()
        }
        let viewModels = handleLoadedEvents(loadedEvents: taskValue.0.events, collectibles: taskValue.1)
        return viewModels
    }
    
    func getAddress() throws -> Address {
        let wallet = try walletProvider.activeWallet
        let publicKey = try wallet.publicKey
        let contract = try contractBuilder.walletContract(
            with: publicKey,
            contractVersion: wallet.contractVersion
        )
        return try contract.address()
    }
    
    func handleLoadedEvents(loadedEvents: [ActivityEvent], collectibles: Collectibles) -> [String: ActivityEventViewModel] {
        let calendar = Calendar.current
        
        var viewModels = [String: ActivityEventViewModel]()
        
        for event in loadedEvents {
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
            
            guard let groupDate = calendar.date(from: dateComponents) else { continue }
            
            events[event.eventId] = event
            
            if let index = eventsSectionIndexTable[groupDate] {
                if !eventsSections[index].eventsIds.contains(event.eventId) {
                    eventsSections[index].eventsIds.append(event.eventId)
                }
                eventsSections[index].eventsIds.sort { lEventId, rEventId in
                    guard let lTimestamp = events[lEventId]?.timestamp,
                          let rTimestamp = events[rEventId]?.timestamp else { return false }
                    return lTimestamp > rTimestamp
                }
            } else {
                let title = activityEventMapper.mapEventsSectionDate(groupDate)
                eventsSections.append(EventsSection(date: groupDate, title: title, eventsIds: [event.eventId]))
                eventsSectionIndexTable[groupDate] = eventsSections.count - 1
            }

            viewModels[event.eventId] = activityEventMapper.mapActivityEvent(event, dateFormat: dateFormat, collectibles: collectibles)
        }
        
        return viewModels
    }
    
    func handleEventsWithNFTs(events: [ActivityEvent]) async -> Collectibles {
        let actions = events.flatMap { $0.actions }
        var nftAddressesToLoad = Set<Address>()
        var nfts = [Address: Collectible]()
        for action in actions {
            switch action.type {
            case .nftItemTransfer(let nftItemTransfer):
                nftAddressesToLoad.insert(nftItemTransfer.nftAddress)
            case .nftPurchase(let nftPurchase):
                nfts[nftPurchase.collectible.address] = nftPurchase.collectible
                try? collectiblesService.saveCollectible(collectible: nftPurchase.collectible)
            default: continue
            }
        }
        
        if let loadedNFTs = try? await collectiblesService.loadCollectibles(addresses: Array(nftAddressesToLoad)) {
            nfts.merge(loadedNFTs.collectibles, uniquingKeysWith: { $1 })
        }
        
        return Collectibles(collectibles: nfts)
    }
    
    func resetContinuation() {
        streamContinuation = nil
    }
}
