//
//  ActivityEventViewModel.swift
//  
//
//  Created by Grigory on 4.8.23..
//

import Foundation
import TonSwift

public struct ActivityEventViewModel {
    public struct ActionViewModel {
        public enum ActionType {
            case sent
            case receieved
            case mint
            case depositStake
            case withdrawStake
            case sentAndReceieved
            case spam
            case jettonSwap
            case bounced
            case subscribed
            case unsubscribed
            case walletInitialized
            case contractExec
            case nftCollectionCreation
            case nftCreation
            case removalFromSale
            case nftPurchase
            case bid
            case putUpForAuction
            case endOfAuction
            case putUpForSale
        }
        
        public struct CollectibleViewModel {
            public let name: String?
            public let collectionName: String?
            public let image: Image
        }
    
        public let eventType: ActionType
        public let amount: String?
        public let subamount: String?
        public let leftTopDescription: String?
        public let leftBottomDescription: String?
        public let date: String
        public let rightTopDesription: String?
        public let status: String?
        public let comment: String?
        public let collectible: CollectibleViewModel?
    }
    
    public let actions: [ActionViewModel]
}
