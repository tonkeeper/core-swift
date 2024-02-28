//
//  FiatMethodsService.swift
//
//
//  Created by Grigory on 14.10.23..
//

import Foundation
import TonAPI

protocol FiatMethodsService {
    func loadFiatMethods(countryCode: String?) async throws -> FiatMethods
    func getFiatMethods() async throws -> FiatMethods
}

actor FiatMethodsServiceImplementation: FiatMethodsService {
    private let api: LegacyAPI
    private let locationAPI: LocationAPI
    private let localRepository: any LocalRepository<FiatMethods>
    
    init(api: LegacyAPI,
         locationAPI: LocationAPI,
         localRepository: any LocalRepository<FiatMethods>) {
        self.api = api
        self.locationAPI = locationAPI
        self.localRepository = localRepository
    }
    
    func loadFiatMethods(countryCode: String?) async throws -> FiatMethods {
        let fiatMethods = try await api.loadFiatMethods(platform: "ios_x", countryCode: countryCode)
        try localRepository.save(item: fiatMethods)
        return fiatMethods
    }
    
    func getFiatMethods() async throws -> FiatMethods {
        return try localRepository.load(key: FiatMethods.fileName)
    }
}
