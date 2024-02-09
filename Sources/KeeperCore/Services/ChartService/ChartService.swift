import Foundation

protocol ChartService {
  func loadChartData(period: Period,
                     token: String,
                     currency: Currency) async throws -> [Coordinate]
}

final class ChartServiceImplementation: ChartService {
  private let api: TonkeeperAPI
  
  init(api: TonkeeperAPI) {
    self.api = api
  }
  
  func loadChartData(period: Period,
                     token: String,
                     currency: Currency) async throws -> [Coordinate] {
    try await api.loadChart(period: period)
  }
}

