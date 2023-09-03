//
//  SendTransactionViewModel.swift
//  
//
//  Created by Grigory on 30.8.23..
//

import Foundation

public enum SendTransactionViewModel {
    case token(SendTokenModel)
    case nft(SendNFTModel)
    
    public enum Item<T> {
        case loading
        case value(T)
    }
    
    public struct SendTokenModel {
        public let title: String
        public let image: Image
        public let recipientAddress: String?
        public let recipientName: String?
        public let amountToken: String?
        public let amountFiat: Item<String?>
        public let feeTon: Item<String?>
        public let feeFiat: Item<String?>
        public let comment: String?
    }
    
    public struct SendNFTModel {
        public let title: String
        public let description: String
        public let image: Image
        public let recipientAddress: String?
        public let recipientName: String?
        public let feeTon: Item<String?>
        public let feeFiat: Item<String?>
        public let comment: String?
        public let nftId: String?
        public let nftCollectionId: String?
    }
}
