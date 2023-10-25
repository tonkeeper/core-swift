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
        try await api.getAccountEvents(
            address: address,
            beforeLt: beforeLt,
            limit: limit
        )
    }
    
    func loadEvents(address: Address, 
                    tokenInfo: TokenInfo,
                    beforeLt: Int64?,
                    limit: Int) async throws -> ActivityEvents {
        try await api.getAccountJettonEvents(
            address: address,
            tokenInfo: tokenInfo,
            beforeLt: beforeLt,
            limit: limit
        )
    }
    
    func loadEvent(accountAddress: Address, 
                   eventId: String) async throws -> ActivityEvent {
        try await api.getEvent(address: accountAddress,
                               eventId: eventId)
    }
}

