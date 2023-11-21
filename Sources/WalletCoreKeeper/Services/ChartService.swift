//
//  ChartService.swift
//
//
//  Created by Grigory on 15.8.23..
//

import Foundation
import TonAPI
import WalletCoreCore

protocol ChartService {
    func loadChartData(period: Period,
                       token: String,
                       currency: Currency) async throws -> [Coordinate]
}

final class ChartServiceImplementation: ChartService {
    private let api: LegacyAPI
    
    init(api: LegacyAPI) {
        self.api = api
    }
    
    func loadChartData(period: Period,
                       token: String,
                       currency: Currency) async throws -> [Coordinate] {
        try await api.loadChart(period: period)
    }
}

