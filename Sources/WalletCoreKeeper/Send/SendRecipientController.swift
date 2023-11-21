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
        if let inputAddress = try? Address.parse(input) {
            if let recipient = try? await loadAccountInfo(address: inputAddress) {
                return recipient
            } else {
                return Recipient(address: inputAddress, domain: nil)
            }
        } else {
            return try await resolveDomain(input)
        }
    }
}

private extension SendRecipientController {
    func resolveDomain(_ input: String) async throws -> Recipient {
        try await domainService.resolveDomainName(input)
    }
    
    func loadAccountInfo(address: Address) async throws -> Recipient {
        let accountInfo = try await accountInfoService.loadAccountInfo(address: address)
        return Recipient(address: address, domain: accountInfo.name)
    }
}
