//
//  WalletItemViewModel.swift
//
//
//  Created by Grigory on 14.7.23..
//

import Foundation

public struct WalletItemViewModel {
    public enum ItemType {
        case ton
        case old
        case token(TokenInfo)
    }
    
    public let type: ItemType
    public let image: Image
    public let leftTitle: String
    public let rightTitle: String?
    public let leftSubtitle: String?
    public let rightSubtitle: String?
    public let rightValue: String?
    public let rightSubvalue: String?
}
