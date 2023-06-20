//
//  MockAPI.swift
//  
//
//  Created by Grigory on 20.6.23..
//

import Foundation
import TonAPI
@testable import WalletCore

final class MockAPI<T: Codable>: API {
    typealias Entity = T
    
    var entity: Entity?
    var delay: TimeInterval = 0
    var sendMethodCalledTimes = 0
    
    func reset() {
        sendMethodCalledTimes = 0
        entity = nil
    }
    
    func send<Entity: Codable, Request: APIRequest<Entity>>(
        request: Request
    ) async throws -> APIResponse<Entity> {
        increateSendMethodCalledTimes()
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        guard let entity = entity else { throw NSError() }
        return APIResponse(
            response: Response(
                statusCode: 200,
                headers: [],
                body: Data()),
            entity: entity as! Entity
        )
    }
    
    private func increateSendMethodCalledTimes() {
        sendMethodCalledTimes += 1
    }
}
