//
//  ActivityListController.swift
//  
//
//  Created by Grigory on 3.8.23..
//

import Foundation
import TonSwift

public actor ActivityListController {
    
    public struct EventsSection {
        public let date: Date
        public let title: String?
        public var eventsIds: [String]
    }
    
    // MARK: - Dependencies
    
    private let activityService: ActivityService
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
    private var loadEventsTask: Task<([ActivityEvent], Collectibles), Error>?
    
    public private(set) var eventsSections = [EventsSection]()
    private var eventsSectionIndexTable = [Date: Int]()
    private var events = [String: ActivityEvent]()

    init(activityService: ActivityService,
         collectiblesService: CollectiblesService,
         walletProvider: WalletProvider,
         contractBuilder: WalletContractBuilder,
         activityEventMapper: ActivityEventMapper) {
        self.activityService = activityService
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
            let loadedEvents = try await activityService.loadEvents(address: try getAddress(), beforeLt: nextFrom, limit: limit)
            try Task.checkCancellation()
            let collectibles = try await loadEventsCollectibles(events: loadedEvents.events)
            try Task.checkCancellation()
            self.nextFrom = loadedEvents.nextFrom
            return (loadedEvents.events, collectibles)
        }
        let taskValue = try await task.value
        let viewModels = handleLoadedEvents(loadedEvents: taskValue.0, collectibles: taskValue.1)
        return viewModels
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
    
    func loadEventsCollectibles(events: [ActivityEvent]) async throws -> Collectibles {
        let nftItemsAddresses = events.map { event in
            return event.actions.compactMap { action -> Address? in
                guard case let .nftItemTransfer(nftItem) = action.type else { return nil }
                return nftItem.nftAddress
            }
        }.flatMap { $0 }
        guard !nftItemsAddresses.isEmpty else { return Collectibles(collectibles: [:]) }
        
        do {
            return try await collectiblesService.loadCollectibles(addresses: nftItemsAddresses)
        } catch {
            guard let cachedCollectibles = try? collectiblesService.getCollectibles() else { return Collectibles(collectibles: [:]) }
            return cachedCollectibles
        }
    }
}
