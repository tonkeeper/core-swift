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
    func loadEvents(address: Address, beforeLt: Int64?, limit: Int) async throws -> ActivityEvents
}

final class ActivityServiceImplementation: ActivityService {
    private let api: API
    
    init(api: API) {
        self.api = api
    }
    
    func loadEvents(address: Address, beforeLt: Int64?, limit: Int) async throws -> ActivityEvents {
        let request = AccountEventsRequest(
            accountId: address.toString(),
            beforeLt: beforeLt,
            limit: limit,
            startDate: nil,
            endDate: nil)
        let response = try await api.send(request: request)
        
        let events: [ActivityEvent] = response.entity.events.compactMap {
            guard let activityEvent = try? ActivityEvent(accountEvent: $0) else { return nil }
            return activityEvent
        }
                
        return ActivityEvents(events: events, startFrom: beforeLt ?? 0, nextFrom: response.entity.nextFrom)
    }
}

