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
        let request = ChartRequest(period: period.stringValue)
        let response = try await api.send(request: request)
        return response.entity.coordinates
    }
}

