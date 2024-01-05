//
//  DeeplinkGenerator.swift
//  
//
//  Created by Grigory on 4.7.23..
//

import Foundation
import TonSwift

public struct DeeplinkGenerator {
    public func generateTransferDeeplink(with string: String) throws -> TonDeeplink {
        let recipientAddress = try Recipient.RecipientAddress(string: string)
        let recipient = Recipient(address: recipientAddress, domain: nil)
        return TonDeeplink.transfer(recipient: recipient)
    }
}
