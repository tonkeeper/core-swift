//
//  RemoteConfiguration.swift
//  
//
//  Created by Grigory on 20.6.23..
//

import Foundation
import TonAPI

struct RemoteConfiguration: Codable {
    struct Flags: Codable {
        let disableSwap: Bool
        let disableExchangeMethods: Bool
        let disableFeedbackButton: Bool
        let disableSupportButton: Bool
        let disableNftMarkets: Bool
        let disableApperance: Bool
        let disableDapps: Bool
        
        enum CodingKeys: String, CodingKey {
            case disableSwap = "disable_swap"
            case disableExchangeMethods = "disable_exchange_methods"
            case disableFeedbackButton = "disable_feedback_button"
            case disableSupportButton = "disable_support_button"
            case disableNftMarkets = "disable_nft_markets"
            case disableApperance = "disable_apperance"
            case disableDapps = "disable_dapps"
        }
    }
    
    let amplitudeKey: String
    let neocryptoWebView: String
    let supportLink: String
    let isExchangeEnabled: String
    let exchangePostUrl: String
    let nftOnExplorerUrl: String
    let transactionExplorer: String
    let accountExplorer: String
    let mercuryoSecret: String
    let tonNFTsMarketplaceEndpoint: String
    let tonapiV2Endpoint: String
    let tonapiTestnetHost: String
    let tonNFTsAPIEndpoint: String
    let tonApiV2Key: String
    let appsflyerDevKey: String
    let appsflyerAppId: String
    let directSupportUrl: String
    let stonfiUrl: String
    
    var isExchangeEnabledBool: Bool {
        Bool(isExchangeEnabled) ?? false
    }
    
    enum CodingKeys: String, CodingKey {
        case amplitudeKey
        case neocryptoWebView
        case supportLink
        case isExchangeEnabled
        case exchangePostUrl
        case nftOnExplorerUrl = "NFTOnExplorerUrl"
        case transactionExplorer
        case accountExplorer
        case mercuryoSecret
        case tonNFTsMarketplaceEndpoint
        case tonapiV2Endpoint
        case tonapiTestnetHost
        case tonNFTsAPIEndpoint
        case tonApiV2Key
        case appsflyerDevKey
        case appsflyerAppId
        case directSupportUrl
        case stonfiUrl
    }
}
