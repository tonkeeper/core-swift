//
//  Deeplink.swift
//  
//
//  Created by Grigory on 4.7.23..
//

import Foundation
import TonSwift

public enum Deeplink {
    case ton(TonDeeplink)
    case tonConnect(TonConnectDeeplink)
    
    public var string: String {
        switch self {
        case .ton(let tonDeeplink):
            return tonDeeplink.string
        case .tonConnect(let tonConnectDeeplink):
            return tonConnectDeeplink.string
        }
    }
}

public enum TonDeeplink {
    case transfer(recipient: Recipient)
    
    public var string: String {
        let ton = "ton://"
        switch self {
        case let .transfer(recipient):
            return "\(ton)transfer/\(recipient.address.toString())"
        }
    }
}

public struct TonConnectDeeplink {
    let string: String
}
