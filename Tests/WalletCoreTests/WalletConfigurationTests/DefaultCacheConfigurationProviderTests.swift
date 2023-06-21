//
//  DefaultCacheConfigurationProviderTests.swift
//  
//
//  Created by Grigory on 21.6.23..
//

import XCTest
@testable import WalletCore

final class DefaultCacheConfigurationProviderTests: XCTestCase {
    
    let fileManager: FileManager = .default
    var cachePath: URL {
        fileManager.temporaryDirectory.appendingPathComponent("DefaultCacheConfigurationProviderTests")
    }
    
    override func setUp() {
        super.setUp()
        try? fileManager.removeItem(at: cachePath)
    }

    func testCacheConfigurationProviderSaveConfigurationSuccess() throws {
        let provider = DefaultCacheConfigurationProvider(cachePath: cachePath,
                                                         fileManager: fileManager)
        let configuration = RemoteConfiguration.configuration()
        XCTAssertNoThrow(try provider.saveConfiguration(configuration))
        XCTAssertNoThrow(try provider.configuration)
        let cachedConfiguration = try provider.configuration
        XCTAssertEqual(cachedConfiguration, configuration)
    }
    
    func testCacheConfigurationProviderSaveConfigurationSuccessIfAlreadySaved() throws {
        let provider = DefaultCacheConfigurationProvider(cachePath: cachePath,
                                                         fileManager: fileManager)
        let configuration = RemoteConfiguration.configuration()
        XCTAssertNoThrow(try provider.saveConfiguration(configuration))
        let otherConfiguration = RemoteConfiguration.configuration(
            amplitudeKey: "ApmlitudeKey",
            accountExplorer: "AccountExplorer"
        )
        XCTAssertNoThrow(try provider.saveConfiguration(otherConfiguration))
        XCTAssertNoThrow(try provider.configuration)
        let cachedConfiguration = try provider.configuration
        XCTAssertEqual(cachedConfiguration, otherConfiguration)
    }
    
    func testCacheConfigurationProviderThrowsErrorIfNoCachedConfigurationSaved() throws {
        let provider = DefaultCacheConfigurationProvider(cachePath: cachePath,
                                                         fileManager: fileManager)
        XCTAssertThrowsError(try provider.configuration, "", { error in
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NSCocoaErrorDomain")
            XCTAssertEqual(nsError.code, 260)
        })
    }
}
