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
    
    public var path: String {
        switch self {
        case let .ton(tonDeeplink):
            return "ton://\(tonDeeplink.path)"
        }
    }
}

public enum TonDeeplink {
    case transfer(address: String)
    
    var path: String {
        switch self {
        case let .transfer(address):
            return "transfer/\(address)"
        }
    }
}
