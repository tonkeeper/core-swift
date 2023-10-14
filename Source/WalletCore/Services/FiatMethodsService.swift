//
//  FiatMethodsService.swift
//
//
//  Created by Grigory on 14.10.23..
//

import Foundation
import TonAPI

protocol FiatMethodsService {
    func loadFiatMethods() async throws -> FiatMethods
    func getFiatMethods() async throws -> FiatMethods
}

actor FiatMethodsServiceImplementation: FiatMethodsService {
    private let api: API
    private let localRepository: any LocalRepository<FiatMethods>
    
    init(api: API,
         localRepository: any LocalRepository<FiatMethods>) {
        self.api = api
        self.localRepository = localRepository
    }
    
    func loadFiatMethods() async throws -> FiatMethods {
        let request = FiatMethodsRequest()
        let response = try await api.send(request: request)
        
        return response.entity.data
    }
    
    func getFiatMethods() async throws -> FiatMethods {
        return try localRepository.load(key: FiatMethods.fileName)
    }
}
