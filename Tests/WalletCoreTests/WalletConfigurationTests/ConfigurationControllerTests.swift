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
    lazy var loader = ConfigurationLoader(api: mockAPI)
    
    override func setUp() {
        super.setUp()
        mockAPI.reset()
    }
    
    func testConfigurationControllerLoadSuccess() async throws {
        // GIVEN
        let configuration = RemoteConfiguration.configuration(amplitudeKey: "123456")
        mockAPI.entity = configuration
        let controller = ConfigurationController(loader: loader)
        
        // WHEN
        let loadedConfiguration = await controller.loadConfiguration()
        
        // THEN
        XCTAssertEqual(loadedConfiguration.amplitudeKey, configuration.amplitudeKey)
        XCTAssertEqual(mockAPI.sendMethodCalledTimes, 1)
    }
    
    func testConfigurationControllerFailedTwoTimes() async throws {
        // GIVEN
        let configuration = RemoteConfiguration.configuration(amplitudeKey: "123456")
        mockAPI.entity = configuration
        mockAPI.errors = [NSError(domain: "", code: 0), NSError(domain: "", code: 0)]
        let controller = ConfigurationController(loader: loader)
        
        // WHEN
        let loadedConfiguration = await controller.loadConfiguration()
        
        // THEN
        XCTAssertEqual(loadedConfiguration.amplitudeKey, configuration.amplitudeKey)
        XCTAssertEqual(mockAPI.sendMethodCalledTimes, 3)
    }
    
    func testConfigurationControllerFailedThreeTimes() async throws {
        // GIVEN
        let configuration = RemoteConfiguration.configuration(amplitudeKey: "123456")
        mockAPI.entity = configuration
        mockAPI.errors = [NSError(domain: "", code: 0), NSError(domain: "", code: 0), NSError(domain: "", code: 0)]
        let controller = ConfigurationController(loader: loader)
        // TBD - use mock default configuration provider to provide default configuration to ConfigurationController
        let defaultConfiguration = RemoteConfiguration.configuration()
        
        // WHEN
        let loadedConfiguration = await controller.loadConfiguration()
        
        // THEN
        XCTAssertEqual(loadedConfiguration.amplitudeKey, defaultConfiguration.amplitudeKey)
        XCTAssertEqual(mockAPI.sendMethodCalledTimes, 3)
    }
    
    func testConfigurationControllerNotifyObserversWhenLoadedConfiguration() async throws {
        // GIVEN
        let configuration = RemoteConfiguration.configuration(amplitudeKey: "123456")
        mockAPI.entity = configuration
        let mockObserverOne = MockConfigurationControllerObserver()
        let mockObserverTwo = MockConfigurationControllerObserver()
        let controller = ConfigurationController(loader: loader)
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
        let configuration = RemoteConfiguration.configuration(amplitudeKey: "123456")
        mockAPI.entity = configuration
        let mockObserverOne = MockConfigurationControllerObserver()
        let mockObserverTwo = MockConfigurationControllerObserver()
        let controller = ConfigurationController(loader: loader)
        await controller.addObserver(mockObserverOne)
        await controller.addObserver(mockObserverTwo)
        
        // WHEN
        _ = await controller.loadConfiguration()
        _ = await controller.loadConfiguration()
        
        // THEN
        XCTAssertEqual(mockObserverOne.notifyCount, 2)
        XCTAssertEqual(mockObserverTwo.notifyCount, 2)
    }
}

private final class MockConfigurationControllerObserver: ConfigurationControllerObserver {
    var notifyCount = 0
    
    func configurationControllerDidUpdateConfigutation(_ configurationController: ConfigurationController) {
        notifyCount += 1
    }
}
