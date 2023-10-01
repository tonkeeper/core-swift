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
    func loadEvents(address: Address, 
                    beforeLt: Int64?,
                    limit: Int) async throws -> ActivityEvents
    func loadEvents(address: Address,
                    tokenInfo: TokenInfo,
                    beforeLt: Int64?,
                    limit: Int) async throws -> ActivityEvents
    func loadEvent(accountAddress: Address,
                   eventId: String) async throws -> ActivityEvent
}

final class ActivityServiceImplementation: ActivityService {
    private let api: API
    
    init(api: API) {
        self.api = api
    }
    
    func loadEvents(address: Address, 
                    beforeLt: Int64?,
                    limit: Int) async throws -> ActivityEvents {
        let request = AccountEventsRequest(
            accountId: address.toRaw(),
            beforeLt: beforeLt,
            limit: limit,
            startDate: nil,
            endDate: nil)
        let response = try await api.send(request: request)
        
        let events: [ActivityEvent] = response.entity.events.compactMap {
            guard let activityEvent = try? ActivityEvent(accountEvent: $0) else { return nil }
            return activityEvent
        }
                
        return ActivityEvents(events: events, 
                              startFrom: beforeLt ?? 0,
                              nextFrom: response.entity.nextFrom)
    }
    
    func loadEvents(address: Address, 
                    tokenInfo: TokenInfo,
                    beforeLt: Int64?,
                    limit: Int) async throws -> ActivityEvents {
        let request = AccountJettonHistoryRequest(
            accountId: address.toRaw(),
            jettonId: tokenInfo.address.toRaw(),
            beforeLt: beforeLt,
            limit: limit,
            startDate: nil,
            endDate: nil)
        let response = try await api.send(request: request)

        let events: [ActivityEvent] = response.entity.events.compactMap {
            guard let activityEvent = try? ActivityEvent(accountEvent: $0) else { return nil }
            return activityEvent
        }

        return ActivityEvents(events: events, 
                              startFrom: beforeLt ?? 0,
                              nextFrom: response.entity.nextFrom)
    }
    
    func loadEvent(accountAddress: Address, 
                   eventId: String) async throws -> ActivityEvent {
        let request = AccountEventRequest(accountId: accountAddress.toRaw(), eventId: eventId)
        let response = try await api.send(request: request)
        return try ActivityEvent(accountEvent: response.entity)
    }
}

