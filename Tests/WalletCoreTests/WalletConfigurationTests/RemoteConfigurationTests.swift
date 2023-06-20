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
          "amplitudeKey": "d3f88d166cd4f4718125ec8bc0bcedf6",
          "tonEndpoint": "https://center.tonkeeper.com/api/v2/jsonRPC",
          "tonApiEndpoint": "https://center.tonkeeper.com/api/v2",
          "tonEndpointAPIKey": "529c56ae2232d7aff74dc1af369b34f60a1ef78a07bd5b01f5e79c453708fe8e",
          "neocryptoWebView": "https://neocrypto.net/buy.html",
          "supportLink": "mailto:support@tonkeeper.com",
          "isExchangeEnabled": "true",
          "exchangePostUrl": "https://t.me/toncoin/703",
          "NFTOnExplorerUrl": "https://tonviewer.com/nft/%s",
          "transactionExplorer": "https://tonviewer.com/transaction/%s",
          "accountExplorer": "https://tonviewer.com/%s",
          "mercuryoSecret": "yMd6dkP9SVip98Nw",
          "tonNFTsMarketplaceEndpoint": "https://ton.diamonds",
          "subscriptionsHost": "https://api.tonkeeper.com",
          "tonapiV2Endpoint": "https://tonapi.io",
          "tonapiIOEndpoint": "https://keeper.tonapi.io",
          "tonapiMainnetHost": "https://keeper.tonapi.io",
          "tonapiTestnetHost": "https://testnet.tonapi.io",
          "tonNFTsAPIEndpoint": "https://keeper.tonapi.io",
          "tonApiKey": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsiMjoyIl0sImp0aSI6IlY0NEIzVFdCM01CUlo3SVciLCJzY29wZSI6ImNsaWVudCIsInN1YiI6InRvbmFwaSJ9.Eh7gz33WRgoaCtZHmQDqJxcD4pJvTGQovEYRqKkN2TshLckcQ_k4btDQQXTURFcRKZkZJSc0MH9tqwuwHPrEvUYKhLxQ9gKLpnDzDsBVmnRG-nJ2yOyqqCeY83EaxrIDDwbmf3vSQP9SaqsMtNUzVTLtsn_RZ41wP594e6uuBXZJPV9g4auHMHj12wvMSL4_vBoEVCrZXP6qktCtUDpqnsBkT9T2iSd61DIC8tOePjrrR3WPqj4qX3w6obCGnc20ZkCHX_yf3XhGWftub7y4zqJ5NWbVcFI4eNdYN5yEEr_9s8v3VCoZqBKF2gUJT2zf7NA5NvYWwX1_EfzC0F3udQ",
          "tonApiV2Key": "AF77F5JNEUSNXPQAAAAMDXXG7RBQ3IRP6PC2HTHL4KYRWMZYOUQGDEKYFDKBETZ6FDVZJBI",
          "appsflyerDevKey": "FtLLvi4MV7hYJDN8Q6KU5m",
          "appsflyerAppId": "1587742107",
          "cachedMediaEndpoint": "https://cache.tonapi.io/imgproxy",
          "cachedMediaKey": "bd03f42aa324a265bc66c9192b29ae71cdb110245e32259b03ed57d901729afb",
          "cachedMediaSalt": "9bd38ff86794264af85aed9384692a573c6a52bb7cd2c7bdaf3ee35392cefbd6",
          "directSupportUrl": "https://t.me/tonkeeper_supportbot",
          "flags": {
            "disable_swap": false,
            "disable_exchange_methods": false,
            "disable_feedback_button": false,
            "disable_support_button": false,
            "disable_nft_markets": false,
            "disable_apperance": false,
            "disable_dapps": false
          },
          "stonfiUrl": "https://tonkeeper.ston.fi/swap"
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