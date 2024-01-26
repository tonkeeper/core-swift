import Foundation
import TonSwift
import TonAPI
import BigInt

protocol JettonBalanceService {
  func loadJettonsBalance(address: Address) async throws -> [JettonBalance]
}

final class JettonBalanceServiceImplementation: JettonBalanceService {
  
  private let api: API
  
  init(api: API) {
    self.api = api
  }
  
  func loadJettonsBalance(address: Address) async throws -> [JettonBalance] {
    let tokensBalance = try await api.getAccountJettonsBalances(address: address)
    return tokensBalance
  }
}
