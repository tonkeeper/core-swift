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

    public struct SendTokenModel {
        public let title: String
        public let image: Image
        public let recipientAddress: String?
        public let recipientName: String?
        public let amountToken: String?
        public let amountFiat: ViewModelLoadableItem<String?>
        public let feeTon: ViewModelLoadableItem<String?>
        public let feeFiat: ViewModelLoadableItem<String?>
        public let comment: String?
    }
    
    public struct SendNFTModel {
        public let title: String
        public let description: String
        public let image: Image
        public let recipientAddress: String?
        public let recipientName: String?
        public let feeTon: ViewModelLoadableItem<String?>
        public let feeFiat: ViewModelLoadableItem<String?>
        public let comment: String?
        public let nftId: String?
        public let nftCollectionId: String?
    }
}
