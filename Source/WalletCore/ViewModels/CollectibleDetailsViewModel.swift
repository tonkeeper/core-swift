//
//  CollectibleDetailsViewModel.swift
//  
//
//  Created by Grigory on 24.8.23..
//

import Foundation

public struct CollectibleDetailsViewModel {
    public struct CollectibleDetails {
        public let imageURL: URL?
        public let title: String?
        public let subtitle: String?
        public let description: String?
    }
    
    public struct CollectionDetails {
        public let title: String?
        public let description: String?
    }
    
    public struct Property {
        public let title: String
        public let value: String
    }
    
    public struct Details {
        public struct Item {
            public let title: String
            public let value: String
        }
        
        public let items: [Item]
        public let url: URL?
    }
    
    public let title: String?
    public let collectibleDetails: CollectibleDetails
    public let collectionDetails: CollectionDetails
    public let properties: [Property]
    public let details: Details
    public let isTransferEnable: Bool
    public let isOnSale: Bool
}
