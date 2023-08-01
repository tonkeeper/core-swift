//
//  DNSService.swift
//  
//
//  Created by Grigory on 1.8.23..
//

import Foundation
import TonAPI
import TonSwift

protocol DNSService {
    func resolveDomainName(_ domainName: String) async throws -> Recipient
}

final class DNSServiceImplementation: DNSService {
    enum Error: Swift.Error {
        case noWalletData
    }
    
    
    private let api: API
    
    init(api: API) {
        self.api = api
    }
    
    func resolveDomainName(_ domainName: String) async throws -> Recipient {
        let parsedDomainName = parseDomainName(domainName)
        let request = ResolveDNSRequest(domainName: parsedDomainName)
        let response = try await api.send(request: request)
        guard let wallet = response.entity.wallet else {
            throw Error.noWalletData
        }
        let address = try Address.parse(wallet.address)
        return Recipient(address: address, domain: parsedDomainName)
    }
}

private extension DNSServiceImplementation {
    func parseDomainName(_ domainName: String) -> String {
        guard let url = URL(string: domainName) else { return domainName }
        if url.pathExtension.isEmpty {
            return "\(domainName).ton"
        }
        return domainName
    }
}
