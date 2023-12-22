import Foundation
import TonAPI

public protocol DateAndTimeCheckService {
  func getTime() async throws -> TimeInterval
}

final class DateAndTimeCheckServiceImplementation: DateAndTimeCheckService {
  private let api: API
  
  init(api: API) {
    self.api = api
  }
  
  func getTime() async throws -> TimeInterval {
    return try await api.getTime()
  }
}

