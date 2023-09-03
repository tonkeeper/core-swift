//
//  ActivityListController.swift
//  
//
//  Created by Grigory on 3.8.23..
//

import Foundation
import TonSwift

public actor ActivityListController {
    
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

    init(activityListLoader: ActivityListLoader,
         collectiblesService: CollectiblesService,
         walletProvider: WalletProvider,
         contractBuilder: WalletContractBuilder,
         activityEventMapper: ActivityEventMapper) {
        self.activityListLoader = activityListLoader
        self.collectiblesService = collectiblesService
        self.walletProvider = walletProvider
        self.contractBuilder = contractBuilder
        self.activityEventMapper = activityEventMapper
    }
    
    public func loadNextEvents() async throws -> [String: ActivityEventViewModel] {
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
    
    public func reset() {
        loadEventsTask?.cancel()
        loadEventsTask = nil
        isLoading = false
        nextFrom = nil
        eventsSections = []
        eventsSectionIndexTable = [:]
        events = [:]
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
            
            if let index = eventsSectionIndexTable[groupDate] {
                eventsSections[index].eventsIds.append(event.eventId)
            } else {
                let title = activityEventMapper.mapEventsSectionDate(groupDate)
                eventsSections.append(EventsSection(date: groupDate, title: title, eventsIds: [event.eventId]))
                eventsSectionIndexTable[groupDate] = eventsSections.count - 1
            }

            events[event.eventId] = event
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
}
