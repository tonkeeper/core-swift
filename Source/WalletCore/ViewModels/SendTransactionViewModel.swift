//
//  SendTransactionViewModel.swift
//  
//
//  Created by Grigory on 28.7.23..
//

import Foundation

public struct SendTransactionViewModel {
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
