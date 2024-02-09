import Foundation

public final class ChartController {
  
  public var didUpdateChartData: (() -> Void)?
  
  private let chartService: ChartService
  private let ratesStore: RatesStore
  private let currencyStore: CurrencyStore
  private let decimalAmountFormatter: DecimalAmountFormatter
  private let dateFormatter = DateFormatter()
  
  private var loadChartDataTask: Task<[Coordinate], Error>?
  public private(set) var coordinates = [Coordinate]()
  
  init(chartService: ChartService,
       ratesStore: RatesStore,
       currencyStore: CurrencyStore,
       decimalAmountFormatter: DecimalAmountFormatter) {
    self.chartService = chartService
    self.ratesStore = ratesStore
    self.currencyStore = currencyStore
    self.decimalAmountFormatter = decimalAmountFormatter
  }
  
  public func getChartData(period: Period) async throws -> [Coordinate] {
    loadChartDataTask?.cancel()
    let currency = currencyStore.getActiveCurrency()
    let task = Task {
      async let coordinatesTask = self.chartService.loadChartData(
        period: period,
        token: "ton",
        currency: currency)
      let rates = await ratesStore.getRates(jettons: [])
      let coordinates = try await coordinatesTask
      
      try Task.checkCancellation()
      loadChartDataTask = nil
      let converted = convertCoordinates(
        coordinates: coordinates,
        rates: rates,
        currency: currency
      )
      return converted
    }
    self.loadChartDataTask = task
    self.coordinates = try await task.value
    return self.coordinates
  }
  
  public func getInformation(at index: Int, period: Period) -> ChartPointInformationModel {
    guard index < coordinates.count else {
      return ChartPointInformationModel(
        amount: "",
        diff: .init(percent: "", fiat: "", direction: .none),
        date: "")
    }
    let currency = currencyStore.getActiveCurrency()
    let coordinate = coordinates[index]
    
    let percentageValue = calculatePercentageDiff(at: index)
    let fiatValue = calculateFiatDiff(percentage: percentageValue)
    
    let amount = decimalAmountFormatter.format(
      amount: Decimal(coordinate.y),
      maximumFractionDigits: 4,
      currency: currency)
    var percentage = String(format: "%.2f%%", percentageValue)
    let fiat = decimalAmountFormatter.format(
      amount: Decimal(fiatValue),
      maximumFractionDigits: 2,
      currency: currency)
    let date = formatTimeInterval(coordinate.x, period: period) ?? ""
    
    let diffDirection: ChartPointInformationModel.Diff.Direction
    if percentageValue > 0 {
      diffDirection = .up
      percentage = "+" + percentage
    } else if percentageValue < 0 {
      diffDirection = .down
    } else {
      diffDirection = .none
    }
    
    return ChartPointInformationModel(
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
  
  // TODO: Remove once tonapi v2 chart request will fit requirements
  func convertCoordinates(coordinates: [Coordinate],
                          rates: Rates,
                          currency: Currency) -> [Coordinate] {
    guard let currencyRates = rates.ton.first(where: { $0.currency == currency }),
          let usdRates = rates.ton.first(where: { $0.currency == .USD }) else {
      return coordinates
    }
    let coeff = NSDecimalNumber(decimal: usdRates.rate / currencyRates.rate).doubleValue
    return coordinates.map { coordinate in
      return .init(x: coordinate.x, y: coordinate.y / coeff)
    }
  }
}

extension ChartController: RatesStoreObserver {
  func didGetRatesStoreEvent(_ event: RatesStore.Event) {
    didUpdateChartData?()
  }
}

extension ChartController: CurrencyStoreObserver {
  func didGetCurrencyStoreEvent(_ event: CurrencyStoreEvent) {
    didUpdateChartData?()
  }
}
