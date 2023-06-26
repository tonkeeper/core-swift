//
//  ConfigurationControllerTests.swift
//  
//
//  Created by Grigory on 20.6.23..
//

import XCTest
@testable import WalletCore

final class ConfigurationControllerTests: XCTestCase {
    let mockAPI = MockAPI<RemoteConfiguration>()
    let mockDefaultConfigurationProvider = MockDefaultConfigurationProvider()
    let mockCacheConfigurationProvider = MockCacheConfigurationProvider()
    lazy var loader = ConfigurationLoader(api: mockAPI)
    
    override func setUp() {
        super.setUp()
        mockAPI.reset()
    }
    
    func testConfigurationControllerLoadSuccess() async throws {
        // GIVEN
        let configuration = RemoteConfiguration.configuration(tonapiV2Endpoint: "123456")
        mockAPI.entity = configuration
        let controller = ConfigurationController(
            loader: loader,
            defaultConfigurationProvider: mockDefaultConfigurationProvider,
            cacheConfigurationProvider: mockCacheConfigurationProvider
        )
        
        // WHEN
        let loadedConfiguration = await controller.loadConfiguration()
        
        // THEN
        XCTAssertEqual(loadedConfiguration.tonapiV2Endpoint, configuration.tonapiV2Endpoint)
        XCTAssertEqual(mockAPI.sendMethodCalledTimes, 1)
    }
    
    func testConfigurationControllerFailedTwoTimes() async throws {
        // GIVEN
        let configuration = RemoteConfiguration.configuration(tonapiV2Endpoint: "123456")
        mockAPI.entity = configuration
        mockAPI.errors = [NSError(domain: "", code: 0), NSError(domain: "", code: 0)]
        let controller = ConfigurationController(
            loader: loader,
            defaultConfigurationProvider: mockDefaultConfigurationProvider,
            cacheConfigurationProvider: mockCacheConfigurationProvider
        )
        
        // WHEN
        let loadedConfiguration = await controller.loadConfiguration()
        
        // THEN
        XCTAssertEqual(loadedConfiguration.tonapiV2Endpoint, configuration.tonapiV2Endpoint)
        XCTAssertEqual(mockAPI.sendMethodCalledTimes, 3)
    }
    
    func testConfigurationControllerFailedThreeTimes() async throws {
        // GIVEN
        let configuration = RemoteConfiguration.configuration(tonapiV2Endpoint: "123456")
        mockAPI.entity = configuration
        mockAPI.errors = [NSError(domain: "", code: 0), NSError(domain: "", code: 0), NSError(domain: "", code: 0)]
        let defaultConfigurationProvider = DefaultConfigurationProvider(
            defaultConfigurationFileName: "TestsDefaultConfiguration.json",
            bundle: .module
        )
        let controller = ConfigurationController(
            loader: loader,
            defaultConfigurationProvider: defaultConfigurationProvider,
            cacheConfigurationProvider: mockCacheConfigurationProvider
        )
        
        // WHEN
        let loadedConfiguration = await controller.loadConfiguration()
        let defaultConfiguration = try defaultConfigurationProvider.configuration
        
        // THEN
        XCTAssertEqual(loadedConfiguration.tonapiV2Endpoint, defaultConfiguration.tonapiV2Endpoint)
        XCTAssertEqual(mockAPI.sendMethodCalledTimes, 3)
    }
    
    func testConfigurationControllerNotifyObserversWhenLoadedConfiguration() async throws {
        // GIVEN
        let configuration = RemoteConfiguration.configuration(tonapiV2Endpoint: "123456")
        mockAPI.entity = configuration
        let mockObserverOne = MockConfigurationControllerObserver()
        let mockObserverTwo = MockConfigurationControllerObserver()
        let controller = ConfigurationController(
            loader: loader,
            defaultConfigurationProvider: mockDefaultConfigurationProvider,
            cacheConfigurationProvider: mockCacheConfigurationProvider
        )
        await controller.addObserver(mockObserverOne)
        await controller.addObserver(mockObserverTwo)
        
        // WHEN
        _ = await controller.loadConfiguration()
        
        // THEN
        XCTAssertEqual(mockObserverOne.notifyCount, 1)
        XCTAssertEqual(mockObserverTwo.notifyCount, 1)
    }
    
    func testConfigurationControllerNotifyObserversTwiceWhenLoadedConfigurationTwice() async throws {
        // GIVEN
        let configuration = RemoteConfiguration.configuration(tonapiV2Endpoint: "123456")
        mockAPI.entity = configuration
        let mockObserverOne = MockConfigurationControllerObserver()
        let mockObserverTwo = MockConfigurationControllerObserver()
        let controller = ConfigurationController(
            loader: loader,
            defaultConfigurationProvider: mockDefaultConfigurationProvider,
            cacheConfigurationProvider: mockCacheConfigurationProvider
        )
        await controller.addObserver(mockObserverOne)
        await controller.addObserver(mockObserverTwo)
        
        // WHEN
        _ = await controller.loadConfiguration()
        _ = await controller.loadConfiguration()
        
        // THEN
        XCTAssertEqual(mockObserverOne.notifyCount, 2)
        XCTAssertEqual(mockObserverTwo.notifyCount, 2)
    }
    
    func testConfigurationControllerSaveToCacheAfterLoading() async throws {
        // GIVEN
        let controller = ConfigurationController(
            loader: loader,
            defaultConfigurationProvider: mockDefaultConfigurationProvider,
            cacheConfigurationProvider: mockCacheConfigurationProvider
        )
        let configuration = RemoteConfiguration.configuration(tonapiV2Endpoint: "123456")
        mockAPI.entity = configuration
        
        // WHEN
        // THEN
        XCTAssertNil(mockCacheConfigurationProvider._configuration)
        XCTAssertThrowsError(try mockCacheConfigurationProvider.configuration)
        
        _ = await controller.loadConfiguration()
        
        XCTAssertNotNil(mockCacheConfigurationProvider._configuration)
        XCTAssertNoThrow(try mockCacheConfigurationProvider.configuration)
        XCTAssertEqual(mockCacheConfigurationProvider._configuration, configuration)
    }
    
    func testConfigurationControllerWaitUntilLoadingFinishedIfLoadingInProgress() async throws {
        let controller = ConfigurationController(
            loader: loader,
            defaultConfigurationProvider: mockDefaultConfigurationProvider,
            cacheConfigurationProvider: mockCacheConfigurationProvider
        )
        let configuration = RemoteConfiguration.configuration(tonapiV2Endpoint: "LoadedtonapiV2Endpoint")
        mockAPI.entity = configuration
        
        mockCacheConfigurationProvider._configuration = RemoteConfiguration.configuration(
            tonapiV2Endpoint: "DefaulttonapiV2Endpoint"
        )
        
        async let loadConfigurationTask = controller.loadConfiguration()
        try await Task.sleep(nanoseconds: 500_000)
        async let getConfigurationTask = controller.configuration
        
        let loadConfiguration = await loadConfigurationTask
        let getConfiguration = await getConfigurationTask

        XCTAssertEqual(getConfiguration, loadConfiguration)
    }
}

private final class MockConfigurationControllerObserver: ConfigurationControllerObserver {
    var notifyCount = 0
    
    func configurationControllerDidUpdateConfigutation(_ configurationController: ConfigurationController) {
        notifyCount += 1
    }
}
