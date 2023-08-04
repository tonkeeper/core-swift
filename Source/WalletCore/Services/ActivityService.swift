//
//  ActivityService.swift
//  
//
//  Created by Grigory on 3.8.23..
//

import Foundation
import TonAPI
import TonSwift

protocol ActivityService {
    func loadInitialEvents(address: Address, limit: Int) async throws -> ActivityEvents
    func loadEvents(address: Address, from: Int64, limit: Int) async throws -> ActivityEvents
}

final class ActivityServiceImplementation: ActivityService {
    private let api: API
    
    init(api: API) {
        self.api = api
    }
    
    func loadInitialEvents(address: Address, limit: Int) async throws -> ActivityEvents {
        let request = AccountEventsRequest(
            accountId: address.toString(),
            beforeLt: nil,
            limit: limit,
            startDate: nil,
            endDate: nil)
        let response = try await api.send(request: request)
        
        let events: [ActivityEvent] = response.entity.events.map { ActivityEvent(accountEvent: $0) }
        return ActivityEvents(events: events, nextFrom: response.entity.nextFrom)
    }
    
    func loadEvents(address: Address, from: Int64, limit: Int) async throws -> ActivityEvents {
        let request = AccountEventsRequest(
            accountId: address.toString(),
            beforeLt: nil,
            limit: limit,
            startDate: from,
            endDate: nil)
        let response = try await api.send(request: request)
        
        let events: [ActivityEvent] = response.entity.events.map { ActivityEvent(accountEvent: $0) }
        return ActivityEvents(events: events, nextFrom: response.entity.nextFrom)
    }
}

