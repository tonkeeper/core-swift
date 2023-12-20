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
    func cachedEvents(address: Address) throws -> ActivityEvents
    func cachedEvents(address: Address, tokenInfo: TokenInfo) throws -> ActivityEvents
    func loadEvents(address: Address,
                    beforeLt: Int64?,
                    limit: Int) async throws -> ActivityEvents
    func loadEvents(address: Address,
                    tokenInfo: TokenInfo,
                    beforeLt: Int64?,
                    limit: Int) async throws -> ActivityEvents
    func loadEvent(accountAddress: Address,
                   eventId: String) async throws -> AccountEvent
}

final class ActivityServiceImplementation: ActivityService {
    private let api: API
    private let localRepository: any LocalRepository<ActivityEvents>
    
    init(api: API,
         localRepository: any LocalRepository<ActivityEvents>) {
        self.api = api
        self.localRepository = localRepository
    }
    
    func cachedEvents(address: Address) throws -> ActivityEvents {
        try localRepository.load(key: address.toRaw())
    }
    
    func cachedEvents(address: Address, tokenInfo: TokenInfo) throws -> ActivityEvents {
        let key = address.toRaw() + tokenInfo.address.toRaw()
        return try localRepository.load(key: key)
    }
    
    func loadEvents(address: Address, 
                    beforeLt: Int64?,
                    limit: Int) async throws -> ActivityEvents {
        let events = try await api.getAccountEvents(
            address: address,
            beforeLt: beforeLt,
            limit: limit
        )
        if events.startFrom == 0 {
            try? localRepository.save(item: events)
        }
        return events
    }
    
    func loadEvents(address: Address, 
                    tokenInfo: TokenInfo,
                    beforeLt: Int64?,
                    limit: Int) async throws -> ActivityEvents {
        let events = try await api.getAccountJettonEvents(
            address: address,
            tokenInfo: tokenInfo,
            beforeLt: beforeLt,
            limit: limit
        )
        if events.startFrom == 0 {
            let key = address.toRaw() + tokenInfo.address.toRaw()
            try? localRepository.save(item: events, key: key)
        }
        return events
    }
    
    func loadEvent(accountAddress: Address, 
                   eventId: String) async throws -> AccountEvent {
        try await api.getEvent(address: accountAddress,
                               eventId: eventId)
    }
}

