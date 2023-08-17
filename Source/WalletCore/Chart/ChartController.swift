//
//  ChartController.swift
//
//
//  Created by Grigory on 15.8.23..
//

import Foundation

public actor ChartController {
    public enum Period: CaseIterable {
        case hour
        case day
        case week
        case month
        case halfYear
        case year
        
        public var title: String {
            switch self {
            case .hour: return "H"
            case .day: return "D"
            case .week: return "W"
            case .month: return "M"
            case .halfYear: return "6M"
            case .year: return "Y"
            }
        }
        
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
    private let dateFormatter = DateFormatter()
    
    private var loadChartDataTask: Task<[Coordinate], Error>?
    public private(set) var coordinates = [Coordinate]()
    
    init(chartService: ChartService) {
        self.chartService = chartService
    }
    
    public func getChartData(period: Period) async throws -> [Coordinate] {
        loadChartDataTask?.cancel()
        let task = Task {
            let coordinates = try await chartService.loadChartData(period: period.stringValue)
            try Task.checkCancellation()
            return coordinates
        }
        self.loadChartDataTask = task
        self.coordinates = try await task.value
        return self.coordinates
    }
    
    public func getInformation(at index: Int, period: Period) -> ChartPointInformationViewModel {
        guard index < coordinates.count else {
            return ChartPointInformationViewModel(
                amount: "",
                diff: .init(percent: "", fiat: "", direction: .none),
                date: "")
        }
        let coordinate = coordinates[index]
        
        let percentageValue = calculatePercentageDiff(at: index)
        let fiatValue = calculateFiatDiff(percentage: percentageValue)
        
        
        let amount = String(format: "\(Currency.USD.symbol ?? "")%.4f", coordinate.y)
        var percentage = String(format: "%.2f%%", percentageValue)
        let fiat = String(format: "\(Currency.USD.symbol ?? "")%.2f", fiatValue)
        let date = formatTimeInterval(coordinate.x, period: period) ?? ""
        
        let diffDirection: ChartPointInformationViewModel.Diff.Direction
        if percentageValue > 0 {
            diffDirection = .up
            percentage = "+" + percentage
        } else if percentageValue < 0 {
            diffDirection = .down
        } else {
            diffDirection = .none
        }

        return ChartPointInformationViewModel(
            amount: amount,
            diff: .init(percent: percentage, fiat: fiat, direction: diffDirection),
            date: date)
    }
}

private extension ChartController {
    func calculatePercentageDiff(at index: Int) -> Double {
        let startValue = coordinates[0].y
        guard startValue != 0 else { return 0 }
        let endValue = coordinates[index].y
        let percentDiff = (endValue/startValue - 1) * 100
        return percentDiff
    }
    
    func calculateFiatDiff(percentage: Double) -> Double {
        let startValue = coordinates[0].y
        let fiatDiff = (startValue / 100) * percentage
        return abs(fiatDiff)
    }
    
    func formatTimeInterval(_ timeInterval: TimeInterval, 
                            period: Period) -> String? {
        
        let dateFormat: String
        switch period {
        case .hour: dateFormat = "E',' d MMM hh:mm"
        case .day: dateFormat = "E',' d MMM hh:mm"
        case .week: dateFormat = "E',' d MMM hh:mm"
        case .month: dateFormat = "E',' d MMM"
        case .halfYear: dateFormat = "yyyy E',' d MMM"
        case .year: dateFormat = "yyyy E',' d MMM"
        }
        
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale.init(identifier: "EN")
        
        return dateFormatter.string(from: Date(timeIntervalSince1970: timeInterval))
    }
}
