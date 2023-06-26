//
//  RemoteConfigurationTests.swift
//  
//
//  Created by Grigory on 20.6.23..
//

import XCTest
import TonAPI
@testable import WalletCore

final class RemoteConfigurationTests: XCTestCase {
    func testRemoteConfigurationModelDecoding() throws {
        let configurationResponseString = """
        {
          "tonapiV2Endpoint": "https://tonapi.io",
          "tonapiTestnetHost": "https://testnet.tonapi.io",
          "tonApiV2Key": "AF77F5JNEUSNXPQAAAAMDXXG7RBQ3IRP6PC2HTHL4KYRWMZYOUQGDEKYFDKBETZ6FDVZJBI",
        }
        """
        
        let decoder = JSONDecoder()
        XCTAssertNoThrow(try decoder.decode(RemoteConfiguration.self, from: configurationResponseString.data(using: .utf8)!))
    }
    
    func testLoadConfigurationRequest() throws {
        // GIVEN
        let requestBuilder = URLRequestBuilder()
        let baseURL = URL(string: "https://tonkeeper.io")!
        let lang = "en"
        let build = "9.9.9"
        let chainName = "testnet"
        let platform = "macos"
        let apiRequest = LoadConfigurationRequest(
            lang: lang,
            build: build,
            chainName: chainName,
            platform: platform)
        let urlString = "\(baseURL.absoluteString)/keys?lang=\(lang)&build=\(build)&chainName=\(chainName)&platform=\(platform)"
        
        // WHEN
        let urlRequest = try requestBuilder.build(with: apiRequest.request, baseURL: baseURL)
        
        // THEN
        XCTAssertEqual(urlRequest.url!.absoluteString, urlString)
    }
}
