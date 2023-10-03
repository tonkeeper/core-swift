//
//  ChartController.swift
//
//
//  Created by Grigory on 15.8.23..
//

import Foundation

public enum Period: CaseIterable {
    case hour
    case day
    case week
    case month
    case halfYear
    case year
    
    public var startDate: Date {
        let calendar = Calendar.current
        switch self {
        case .day:
            return calendar.date(byAdding: DateComponents(day: -1), to: Date())!
        case .halfYear:
            return calendar.date(byAdding: DateComponents(year: -6), to: Date())!
        case .hour:
            return calendar.date(byAdding: DateComponents(hour: -1), to: Date())!
        case .month:
            return calendar.date(byAdding: DateComponents(month: -1), to: Date())!
        case .week:
            return calendar.date(byAdding: DateComponents(day: -7), to: Date())!
        case .year:
            return calendar.date(byAdding: DateComponents(year: -1), to: Date())!
        }
    }
        
    public var endDate: Date {
        Date()
    }
    
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
}

public actor ChartController {
    private let chartService: ChartService
    private let decimalAmountFormatter: DecimalAmountFormatter
    private let dateFormatter = DateFormatter()
    
    private var loadChartDataTask: Task<[Coordinate], Error>?
    public private(set) var coordinates = [Coordinate]()

    init(chartService: ChartService,
         decimalAmountFormatter: DecimalAmountFormatter) {
        self.chartService = chartService
        self.decimalAmountFormatter = decimalAmountFormatter
    }
    
    public func getChartData(period: Period,
                             currency: Currency) async throws -> [Coordinate] {
        loadChartDataTask?.cancel()
        let task = Task {
            let coordinates = try await chartService.loadChartData(
                period: period,
                token: "ton",
            currency: currency)
            try Task.checkCancellation()
            loadChartDataTask = nil
            return coordinates
        }
        self.loadChartDataTask = task
        self.coordinates = try await task.value
        return self.coordinates
    }
    
    public func getInformation(at index: Int, period: Period, currency: Currency) -> ChartPointInformationViewModel {
        guard index < coordinates.count else {
            return ChartPointInformationViewModel(
                amount: "",
                diff: .init(percent: "", fiat: "", direction: .none),
                date: "")
        }
        let coordinate = coordinates[index]
        
        let percentageValue = calculatePercentageDiff(at: index)
        let fiatValue = calculateFiatDiff(percentage: percentageValue)
        
        let amount = decimalAmountFormatter.format(
            amount: Decimal(coordinate.y),
            maximumFractionDigits: 4,
            currency: currency)
        var percentage = String(format: "%.2f%%", percentageValue)
        let fiat = String(format: "\(currency.symbol)%.2f", fiatValue)
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
  
    public func getMaximumValue(currency: Currency) -> String {
        guard let coordinate = coordinates.max(by: { $0.y < $1.y }) else {
            return ""
        }
        return String(format: "\(currency.symbol)%.2f", coordinate.y)
    }
    
    public func getMinimumValue(currency: Currency) -> String {
        guard let coordinate = coordinates.max(by: { $0.y > $1.y }) else {
            return ""
        }
        return String(format: "\(currency.symbol)%.2f", coordinate.y)
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
        case .hour: dateFormat = "E',' d MMM HH:mm"
        case .day: dateFormat = "E',' d MMM HH:mm"
        case .week: dateFormat = "E',' d MMM HH:mm"
        case .month: dateFormat = "E',' d MMM"
        case .halfYear: dateFormat = "yyyy E',' d MMM"
        case .year: dateFormat = "yyyy E',' d MMM"
        }
        
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale.init(identifier: "EN")
        
        return dateFormatter.string(from: Date(timeIntervalSince1970: timeInterval))
    }
}
