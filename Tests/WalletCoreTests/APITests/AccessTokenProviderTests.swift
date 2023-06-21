//
//  AccessTokenProviderTests.swift
//  
//
//  Created by Grigory on 21.6.23..
//

import Foundation
import XCTest
import TonAPI
@testable import WalletCore

final class AccessTokenProviderTests: XCTestCase {
    let mockAPI = MockAPI<RemoteConfiguration>()
    let mockDefaultConfigurationProvider = MockDefaultConfigurationProvider()
    let mockCacheConfigurationProvider = MockCacheConfigurationProvider()
    lazy var loader = ConfigurationLoader(api: mockAPI)
    lazy var configurationController = ConfigurationController(
        loader: loader,
        defaultConfigurationProvider: mockDefaultConfigurationProvider,
        cacheConfigurationProvider: mockCacheConfigurationProvider
    )
    lazy var accessTokenProvider = AccessTokenProvider(
        configurationController: configurationController
    )
    
    override func setUp() {
        super.setUp()
        mockCacheConfigurationProvider._configuration = nil
    }
    
    func testAccessTokenProviderEnrichRequestWithTokenFromLoadedConfiguration() async throws {
        // GIVEN
        let configuration = RemoteConfiguration.configuration(tonApiV2Key: "CachedTonApiV2Key")
        mockCacheConfigurationProvider._configuration = configuration
        
        let request = Request(
            path: "path",
            method: .GET,
            headers: [],
            queryItems: [],
            bodyParameter: [:]
        )
        
        // WHEN
        let updatedRequest = try await accessTokenProvider.intercept(request: request)
        
        // THEN
        XCTAssertEqual(updatedRequest.headers, [.init(name: "Authorization", value: "Bearer CachedTonApiV2Key")])
    }
    
    func testAccessTokenProviderEnrichRequestWithTokenAfterConfigurationFinishedLoading() async throws {
        // GIVEN
        let configuration = RemoteConfiguration.configuration(tonApiV2Key: "CachedTonApiV2Key")
        mockCacheConfigurationProvider._configuration = configuration
        
        let loadedConfiguration = RemoteConfiguration.configuration(tonApiV2Key: "LoadedTonApiV2Key")
        mockAPI.entity = loadedConfiguration
        
        let request = Request(
            path: "path",
            method: .GET,
            headers: [],
            queryItems: [],
            bodyParameter: [:]
        )
        
        // WHEN
        async let loadTask = configurationController.loadConfiguration()
        try await Task.sleep(nanoseconds: 500_000)
        async let interceptTask = accessTokenProvider.intercept(request: request)
        
        _ = await loadTask
        let updatedRequest = try await interceptTask

        // THEN
        XCTAssertEqual(updatedRequest.headers, [.init(name: "Authorization", value: "Bearer LoadedTonApiV2Key")])
    }
}
