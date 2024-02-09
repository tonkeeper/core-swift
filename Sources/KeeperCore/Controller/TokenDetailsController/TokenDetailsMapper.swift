import Foundation
import BigInt

struct TokenDetailsMapper {
  private let amountFormatter: AmountFormatter
  private let rateConverter: RateConverter
  
  init(amountFormatter: AmountFormatter,
       rateConverter: RateConverter) {
    self.amountFormatter = amountFormatter
    self.rateConverter = rateConverter
  }
  
  func mapTonBalance(amount: Int64,
                     tonRates: [Rates.Rate],
                     currency: Currency) -> (tokenAmount: String, convertedAmount: String?) {
    let bigUIntAmount = BigUInt(amount)
    let amount = amountFormatter.formatAmount(
      bigUIntAmount,
      fractionDigits: TonInfo.fractionDigits,
      maximumFractionDigits: TonInfo.fractionDigits,
      symbol: TonInfo.symbol
    )
    
    var convertedAmount: String?
    if let rate = tonRates.first(where: { $0.currency == currency }) {
      let converted = rateConverter.convert(
        amount: bigUIntAmount,
        amountFractionLength: TonInfo.fractionDigits,
        rate: rate
      )
      convertedAmount = amountFormatter.formatAmount(
        converted.amount,
        fractionDigits: converted.fractionLength,
        maximumFractionDigits: 2,
        currency: currency
      )
    }
    
    return (amount, convertedAmount)
  }
  
  func mapJettonBalance(jettonInfo: JettonInfo,
                        jettonAmount: BigUInt,
                        rates: [Rates.Rate],
                        currency: Currency) -> (tokenAmount: String, convertedAmount: String?) {
    let amount = amountFormatter.formatAmount(
      jettonAmount,
      fractionDigits: jettonInfo.fractionDigits,
      maximumFractionDigits: jettonInfo.fractionDigits,
      symbol: jettonInfo.symbol
    )
    
    var convertedAmount: String?
    if let rate = rates.first(where: { $0.currency == currency }) {
      let converted = rateConverter.convert(
        amount: jettonAmount,
        amountFractionLength: jettonInfo.fractionDigits,
        rate: rate
      )
      convertedAmount = amountFormatter.formatAmount(
        converted.amount,
        fractionDigits: converted.fractionLength,
        maximumFractionDigits: 2,
        currency: currency
      )
    }
    return (amount, convertedAmount)
  }
}
