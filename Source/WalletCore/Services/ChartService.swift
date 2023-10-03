//
//  ChartService.swift
//
//
//  Created by Grigory on 15.8.23..
//

import Foundation
import TonAPI

protocol ChartService {
    func loadChartData(period: Period,
                       token: String,
                       currency: Currency) async throws -> [Coordinate]
}

final class ChartServiceImplementation: ChartService {
    private let api: API
    
    init(api: API) {
        self.api = api
    }
    
    func loadChartData(period: Period,
                       token: String,
                       currency: Currency) async throws -> [Coordinate] {
      let request = RatesChartRequest(token: token,
                                      currency: currency.code,
                                      startDate: period.startDate,
                                      endDate: period.endDate)
        let response = try await api.send(request: request)
        return response.entity.points.map { point in
            Coordinate(x: point.date, y: point.value)
        }
    }
}

