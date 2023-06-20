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
        amplitudeKey: String = "",
        neocryptoWebView: String = "",
        supportLink: String = "",
        isExchangeEnabled: String = "",
        exchangePostUrl: String = "",
        nftOnExplorerUrl: String = "",
        transactionExplorer: String = "",
        accountExplorer: String = "",
        mercuryoSecret: String = "",
        tonNFTsMarketplaceEndpoint: String = "",
        tonapiV2Endpoint: String = "",
        tonapiTestnetHost: String = "",
        tonNFTsAPIEndpoint: String = "",
        tonApiV2Key: String = "",
        appsflyerDevKey: String = "",
        appsflyerAppId: String = "",
        directSupportUrl: String = "",
        stonfiUrl: String = ""
    ) -> RemoteConfiguration {
        return RemoteConfiguration(amplitudeKey: amplitudeKey,
                                   neocryptoWebView: neocryptoWebView,
                                   supportLink: supportLink,
                                   isExchangeEnabled: isExchangeEnabled,
                                   exchangePostUrl: exchangePostUrl,
                                   nftOnExplorerUrl: nftOnExplorerUrl,
                                   transactionExplorer: transactionExplorer,
                                   accountExplorer: accountExplorer,
                                   mercuryoSecret: mercuryoSecret,
                                   tonNFTsMarketplaceEndpoint: tonNFTsMarketplaceEndpoint,
                                   tonapiV2Endpoint: tonapiV2Endpoint,
                                   tonapiTestnetHost: tonapiTestnetHost,
                                   tonNFTsAPIEndpoint: tonNFTsAPIEndpoint,
                                   tonApiV2Key: tonApiV2Key,
                                   appsflyerDevKey: appsflyerDevKey,
                                   appsflyerAppId: appsflyerAppId,
                                   directSupportUrl: directSupportUrl,
                                   stonfiUrl: stonfiUrl)
    }
}
