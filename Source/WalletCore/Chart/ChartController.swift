//
//  ChartController.swift
//
//
//  Created by Grigory on 15.8.23..
//

import Foundation

public final class ChartController {
    public enum Period: CaseIterable {
        case hour
        case day
        case week
        case month
        case halfYear
        case year
        
        var stringValue: String {
            switch self {
            case .hour: return "1H"
            case .day: return "1D"
            case .week: return "7D"
            case .month: return "1M"
            case .halfYear: return "6M"
            case .year: return "1Y"
            }
        }
    }
    
    private let chartService: ChartService
    
    init(chartService: ChartService) {
        self.chartService = chartService
    }
    
    public func getChartData(period: Period) async throws -> [Coordinate] {
        return try await chartService.loadChartData(period: period.stringValue)
    }
}
