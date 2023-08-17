//
//  ChartService.swift
//
//
//  Created by Grigory on 15.8.23..
//

import Foundation
import TonAPI

protocol ChartService {
    func loadChartData(period: String) async throws -> [Coordinate]
}

final class ChartServiceImplementation: ChartService {
    private let api: API
    
    init(api: API) {
        self.api = api
    }
    
    func loadChartData(period: String) async throws -> [Coordinate] {
        let request = ChartRequest(period: period)
        let response = try await api.send(request: request)
        return response.entity.coordinates
    }
}

