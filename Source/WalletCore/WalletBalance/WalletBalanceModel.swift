//
//  WalletBalanceModel.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation

public struct WalletBalanceModel {
    public struct Header {
        public let amount: String
        public let address: String
    }
    
    public struct Token {
        public let title: String
        public let shortTitle: String?
        public let price: String?
        public let priceDiff: String?
        public let topAmount: String?
        public let bottomAmount: String?
    }
    
    public struct Collectible {
        public let title: String?
        public let subtitle: String?
        public let imageURL: URL?
    }
    
    public enum Section {
        case token([Token])
        case collectibles([Collectible])
    }
    
    public struct Page {
        public let title: String
        public let sections: [Section]
    }
    
    public let header: Header
    public let pages: [Page]
}
