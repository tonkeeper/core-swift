//
//  DeeplinkGenerator.swift
//  
//
//  Created by Grigory on 4.7.23..
//

import Foundation
import TonSwift

public struct DeeplinkGenerator {
    public func generateTransferDeeplink(with address: String) -> Deeplink {
        Deeplink.ton(.transfer(address: address))
    }
}
