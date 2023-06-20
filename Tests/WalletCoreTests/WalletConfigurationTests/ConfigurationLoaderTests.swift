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
        mockAPI.entity = .empty
        let loader = ConfigurationLoader(api: mockAPI)
        
        // WHEN
        _ = try await loader.fetch()
    
        // THEN
        XCTAssertEqual(mockAPI.sendMethodCalledTimes, 1)
    }
    
    func testConfigurationLoaderDoesntStartLoadingIfAlreadyLoading() async throws {
        // GIVEN
        mockAPI.entity = .empty
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
        mockAPI.entity = .empty
        let loader = ConfigurationLoader(api: mockAPI)

        // WHEN
        _ = try await loader.fetch()
        _ = try await loader.fetch()

        // THEN
        XCTAssertEqual(mockAPI.sendMethodCalledTimes, 2)
    }
}

fileprivate extension RemoteConfiguration {
    static var empty: RemoteConfiguration {
        RemoteConfiguration(
            amplitudeKey: "",
            neocryptoWebView: "",
            supportLink: "",
            isExchangeEnabled: "",
            exchangePostUrl: "",
            nftOnExplorerUrl: "",
            transactionExplorer: "",
            accountExplorer: "",
            mercuryoSecret: "",
            tonNFTsMarketplaceEndpoint: "",
            tonapiV2Endpoint: "",
            tonapiTestnetHost: "",
            tonNFTsAPIEndpoint: "",
            tonApiV2Key: "",
            appsflyerDevKey: "",
            appsflyerAppId: "",
            directSupportUrl: "",
            stonfiUrl: "")
    }
}
