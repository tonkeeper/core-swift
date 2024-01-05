//
//  SendRecipientController.swift
//  
//
//  Created by Grigory on 1.8.23..
//

import Foundation
import TonAPI
import TonSwift

public final class SendRecipientController {
    
    private let domainService: DNSService
    private let accountInfoService: AccountInfoService
    
    init(domainService: DNSService,
         accountInfoService: AccountInfoService) {
        self.domainService = domainService
        self.accountInfoService = accountInfoService
    }
    
    public func handleInput(_ input: String) async throws -> Recipient {
        do {
            let recipientAddress = try Recipient.RecipientAddress(string: input)
            if let recipient = try? await loadAccountInfo(recipientAddress: recipientAddress) {
                return recipient
            } else {
                return Recipient(address: recipientAddress, domain: nil)
            }
        } catch {
            return try await resolveDomain(input)
        }
    }
}

private extension SendRecipientController {
    func resolveDomain(_ input: String) async throws -> Recipient {
        try await domainService.resolveDomainName(input)
    }
    
    func loadAccountInfo(recipientAddress: Recipient.RecipientAddress) async throws -> Recipient {
        let accountInfo = try await accountInfoService.loadAccountInfo(address: recipientAddress.toString())
        return Recipient(address: recipientAddress, domain: accountInfo.name)
    }
}
