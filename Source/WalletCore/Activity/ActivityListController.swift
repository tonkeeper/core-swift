//
//  ActivityListController.swift
//  
//
//  Created by Grigory on 3.8.23..
//

import Foundation
import TonSwift

public actor ActivityListController {
    
    struct EventsGroup {
        let date: Date
        var events: [ActivityEvent]
    }
    
    public struct EventsSection {
        public let date: Date
        public var viewModels: [ActivityEventViewModel]
    }
    
    public struct EventsUpdateModel {
        public let sectionsToUpdate: [EventsSection]
        public let sectionsToAdd: [EventsSection]
    }
    
    // MARK: - Dependencies
    
    private let activityService: ActivityService
    private let walletProvider: WalletProvider
    private let contractBuilder: WalletContractBuilder
    
    // MARK: - State
    
    private var nextFrom: Int64?
    private var eventGroups = [EventsGroup]()
    private var groupsTable = [Date: Int]()
    private let limit: Int = 25
    private var loadEventsTask: Task<[ActivityEvent], Error>?
    
    init(activityService: ActivityService,
         walletProvider: WalletProvider,
         contractBuilder: WalletContractBuilder) {
        self.activityService = activityService
        self.walletProvider = walletProvider
        self.contractBuilder = contractBuilder
    }
    
    public func loadNextEvents() async throws -> EventsUpdateModel {
        loadEventsTask?.cancel()
        let task = Task { () -> [ActivityEvent] in
            let events = try await activityService.loadEvents(address: try getAddress(), beforeLt: nextFrom, limit: limit)
            try Task.checkCancellation()
            self.nextFrom = events.nextFrom
            return events.events
        }
        self.loadEventsTask = task
        return handleLoadedEvents(events: try await task.value)
    }
    
    public func reset() {
        loadEventsTask?.cancel()
        eventGroups = []
        groupsTable = [:]
        nextFrom = nil
    }
    
    public func hasMore() -> Bool {
        nextFrom != 0
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
    
    func handleLoadedEvents(events: [ActivityEvent]) -> EventsUpdateModel {
        let mapper = ActivityEventMapper()
        let calendar = Calendar.current
        
        var eventsGroups = [Date: [ActivityEvent]]()
        var viewModelsGroups = [Date: [ActivityEventViewModel]]()
        
        for event in events {
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
                dateFormat = "MMM dd 'at' HH:mm"
            }
            
            guard let groupDate = calendar.date(from: dateComponents) else { continue }
            
            let groupEvents = eventsGroups[groupDate] ?? []
            eventsGroups[groupDate] = groupEvents + CollectionOfOne(event)
            
            let viewModel = mapper.mapActivityEvent(event, dateFormat: dateFormat)
            let groupViewModels = viewModelsGroups[groupDate] ?? []
            viewModelsGroups[groupDate] = groupViewModels + CollectionOfOne(viewModel)
        }
        
        var sectionsToUpdate = [EventsSection]()
        var sectionsToAdd = [EventsSection]()
        
        for group in eventsGroups.sorted(by: { $0.key > $1.key }) {
            if let index = groupsTable[group.key] {
                self.eventGroups[index].events.append(contentsOf: group.value)
                sectionsToUpdate.append(EventsSection(date: group.key, viewModels: viewModelsGroups[group.key] ?? []))
            } else {
                self.eventGroups.append(EventsGroup(date: group.key, events: group.value))
                self.groupsTable[group.key] = self.eventGroups.count - 1
                sectionsToAdd.append(EventsSection(date: group.key, viewModels: viewModelsGroups[group.key] ?? []))
            }
        }
        
        return EventsUpdateModel(sectionsToUpdate: sectionsToUpdate, sectionsToAdd: sectionsToAdd)
    }
}
