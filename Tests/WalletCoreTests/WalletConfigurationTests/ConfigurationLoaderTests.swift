//
//  ConfigurationLoaderTests.swift
//  
//
//  Created by Grigory on 20.6.23..
//

import XCTest
@testable import WalletCore

final class ConfigurationLoaderTests: XCTestCase {
    
    let mockAPI = MockAPI<RemoteConfiguration>()
    
    override func setUp() {
        super.setUp()
        mockAPI.reset()
    }
    
    func testConfigurationLoaderStartLoading() async throws {
        // GIVEN
        mockAPI.entity = .configuration()
        let loader = ConfigurationLoader(api: mockAPI)
        
        // WHEN
        _ = try await loader.fetch()
    
        // THEN
        XCTAssertEqual(mockAPI.sendMethodCalledTimes, 1)
    }
    
    func testConfigurationLoaderDoesntStartLoadingIfAlreadyLoading() async throws {
        // GIVEN
        mockAPI.entity = .configuration()
        let loader = ConfigurationLoader(api: mockAPI)

        // WHEN
        async let task = loader.fetch()
        async let task2 = loader.fetch()
        async let task3 = loader.fetch()

        let _ = try await [task, task2, task3]

        // THEN
        XCTAssertEqual(mockAPI.sendMethodCalledTimes, 1)
    }
    
    func testConfigurationLoaderStartLoadingAfterFinishedLoading() async throws {
        // GIVEN
        mockAPI.entity = .configuration()
        let loader = ConfigurationLoader(api: mockAPI)

        // WHEN
        _ = try await loader.fetch()
        _ = try await loader.fetch()

        // THEN
        XCTAssertEqual(mockAPI.sendMethodCalledTimes, 2)
    }
    
    func testConfigurationLoaderStartSecondLoadingIfFirstFailed() async throws {
        // GIVEN
        mockAPI.entity = .configuration()
        mockAPI.errors = [NSError(domain: "", code: 0)]
        let loader = ConfigurationLoader(api: mockAPI)

        // WHEN
        do {
            _ = try await loader.fetch()
            XCTFail("Error needs to be thrown.")
        } catch {}
        _ = try await loader.fetch()

        // THEN
        XCTAssertEqual(mockAPI.sendMethodCalledTimes, 2)
    }
}

extension RemoteConfiguration {
    static func configuration(
        tonapiV2Endpoint: String = "",
        tonapiTestnetHost: String = "",
        tonApiV2Key: String = ""
    ) -> RemoteConfiguration {
        return RemoteConfiguration(tonapiV2Endpoint: tonapiV2Endpoint,
                                   tonapiTestnetHost: tonapiTestnetHost,
                                   tonApiV2Key: tonApiV2Key)
    }
}
