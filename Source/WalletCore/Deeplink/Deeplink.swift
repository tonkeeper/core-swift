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
//
//    public var path: String {
//        switch self {
//        case let .ton(tonDeeplink):
//            return "ton://\(tonDeeplink.path)"
//        }
//    }
}

public enum TonDeeplink {
    case transfer(address: Address)
    
    public var path: String {
        let ton = "ton://"
        switch self {
        case let .transfer(address):
            return "\(ton)transfer/\(address.toRaw())"
        }
    }
}

public struct TonConnectDeeplink {
    let string: String
}
