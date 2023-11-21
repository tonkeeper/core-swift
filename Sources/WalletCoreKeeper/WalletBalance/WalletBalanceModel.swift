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
        public let fullAddress: String
        public let shortAddress: String
    }

    public enum Section {
        case token([WalletItemViewModel])
        case collectibles([WalletCollectibleItemViewModel])
    }
    
    public struct Page {
        public let title: String
        public let sections: [Section]
    }
    
    public let header: Header
    public let pages: [Page]
}

public enum Image: Equatable, Hashable {
    case url(URL?)
    case ton
    case oldWallet
}
