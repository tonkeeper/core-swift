//
//  ActivityListLoader.swift
//  
//
//  Created by Grigory on 10.8.23..
//

import Foundation
import TonSwift

protocol ActivityListLoader {
    func loadEvents(address: Address, beforeLt: Int64?, limit: Int) async throws -> ActivityEvents
    func loadEvent(address: Address, eventId: String) async throws -> AccountEvent
}

struct ActivityListAllEventsLoader: ActivityListLoader {
    private let activityService: ActivityService
    
    init(activityService: ActivityService) {
        self.activityService = activityService
    }
    
    func loadEvents(address: Address, 
                    beforeLt: Int64?,
                    limit: Int) async throws -> ActivityEvents {
        return try await activityService.loadEvents(address: address, beforeLt: beforeLt, limit: limit)
    }
    
    func loadEvent(address: Address, eventId: String) async throws -> AccountEvent {
        return try await activityService.loadEvent(accountAddress: address, eventId: eventId)
    }
}

struct ActivityListTonEventsLoader: ActivityListLoader {
    private let activityService: ActivityService
    
    init(activityService: ActivityService) {
        self.activityService = activityService
    }
    
    func loadEvents(address: Address, 
                    beforeLt: Int64?,
                    limit: Int) async throws -> ActivityEvents {
        let loadedEvents = try await activityService.loadEvents(
            address: address,
            beforeLt: beforeLt,
            limit: limit
        )
        
        let filteredEvents = loadedEvents.events.compactMap { event -> AccountEvent? in
            let filteredActions = event.actions.compactMap { action -> Action? in
                guard case .tonTransfer = action.type else { return nil }
                return action
            }
            guard !filteredActions.isEmpty else { return nil }
            return AccountEvent(
                eventId: event.eventId,
                timestamp: event.timestamp,
                account: event.account,
                isScam: event.isScam,
                isInProgress: event.isInProgress,
                fee: event.fee,
                actions: filteredActions
            )
        }
        
        return ActivityEvents(
            events: filteredEvents,
            startFrom: loadedEvents.startFrom,
            nextFrom: loadedEvents.nextFrom
        )
    }
    
    func loadEvent(address: Address, eventId: String) async throws -> AccountEvent {
        return try await activityService.loadEvent(accountAddress: address, eventId: eventId)
    }
}

struct ActivityListTokenEventsLoader: ActivityListLoader {
    private let tokenInfo: TokenInfo
    private let activityService: ActivityService
    
    init(tokenInfo: TokenInfo,
         activityService: ActivityService) {
        self.tokenInfo = tokenInfo
        self.activityService = activityService
    }
    
    func loadEvents(address: Address, 
                    beforeLt: Int64?,
                    limit: Int) async throws -> ActivityEvents {
        return try await activityService.loadEvents(
            address: address,
            tokenInfo: tokenInfo,
            beforeLt: beforeLt,
            limit: limit
        )
    }
    
    func loadEvent(address: Address, eventId: String) async throws -> AccountEvent {
        return try await activityService.loadEvent(accountAddress: address, eventId: eventId)
    }
}
