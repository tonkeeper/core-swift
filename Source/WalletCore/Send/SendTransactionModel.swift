//
//  SendTransactionModel.swift
//  
//
//  Created by Grigory on 7.7.23..
//

import Foundation

public struct SendTransactionModel {
    public let title: String
    public let address: String
    public let amountToken: String
    public let amountFiat: String?
    public let feeTon: String
    public let feeFiat: String?
    public let boc: String
}
