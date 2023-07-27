//
//  SendTransactionModel.swift
//  
//
//  Created by Grigory on 7.7.23..
//

import Foundation

public struct SendTransactionModel {
    public struct TokenTransactionModel {
        public let title: String
        public let image: Image
        public let recipientAddress: String?
        public let recipientName: String?
        public let amountToken: String
        public let amountFiat: String?
        public let feeTon: String
        public let feeFiat: String?
        public let comment: String?
    }
    public let tokenModel: TokenTransactionModel
    public let boc: String
}
