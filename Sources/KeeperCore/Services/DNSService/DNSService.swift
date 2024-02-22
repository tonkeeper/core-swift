import Foundation
import TonAPI
import TonSwift

protocol DNSService {
  func resolveDomainName(_ domainName: String) async throws -> FriendlyAddress
  func loadDomainExpirationDate(_ domainName: String) async throws -> Date?
}

final class DNSServiceImplementation: DNSService {
  enum Error: Swift.Error {
    case noWalletData
  }
  
  private let api: API
  
  init(api: API) {
    self.api = api
  }
  
  func resolveDomainName(_ domainName: String) async throws -> FriendlyAddress {
    let parsedDomainName = parseDomainName(domainName)
    return try await api.resolveDomainName(parsedDomainName)
  }
  
  func loadDomainExpirationDate(_ domainName: String) async throws -> Date? {
    let parsedDomainName = parseDomainName(domainName)
    return try await api.getDomainExpirationDate(parsedDomainName)
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
