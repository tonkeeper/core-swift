import Foundation
import BigInt

struct WalletBalanceMapper {
  
  private let amountFormatter: AmountFormatter
  private let decimalAmountFormatter: DecimalAmountFormatter
  private let rateConverter: RateConverter
  
  init(amountFormatter: AmountFormatter,
       decimalAmountFormatter: DecimalAmountFormatter,
       rateConverter: RateConverter) {
    self.amountFormatter = amountFormatter
    self.decimalAmountFormatter = decimalAmountFormatter
    self.rateConverter = rateConverter
  }
  
  func mapBalance(walletBalance: WalletBalance,
                  rates: Rates,
                  currency: Currency) -> WalletBalanceModel {
    let totalBalance = mapTotalBalance(
      walletBalance: walletBalance,
      rates: rates,
      currency: currency
    )
    
    let tonItem = mapTon(
      tonBalance: walletBalance.balance.tonBalance,
      tonRates: rates.ton,
      currency: currency
    )
    
    let jettonItems = mapJettons(
      jettonsBalance: walletBalance.balance.jettonsBalance,
      jettonsRates: rates.jettonsRates,
      currency: currency
    )
    
    return WalletBalanceModel(total: totalBalance, tonItems: [tonItem], jettonsItems: jettonItems)
  }
  
  func mapTotalBalance(walletBalance: WalletBalance,
                       rates: Rates,
                       currency: Currency) -> String {
    struct Item {
      let amount: BigUInt
      let fractionDigits: Int
    }
    
    var items = [Item]()
    var maximumFractionDigits = 0
    
    // TON
    if let tonRate = rates.ton.first(where: { $0.currency == currency }) {
      let converted = rateConverter.convert(
        amount: walletBalance.balance.tonBalance.amount,
        amountFractionLength: TonInfo.fractionDigits,
        rate: tonRate
      )
      items.append(Item(amount: converted.amount, fractionDigits: converted.fractionLength))
      maximumFractionDigits = converted.fractionLength
    }
    
    // Jettons
    for jettonBalance in walletBalance.balance.jettonsBalance {
      guard let jettonRates = rates.jettonsRates
        .first(where: { $0.jettonInfo == jettonBalance.amount.jettonInfo })?
        .rates
        .first(where: { $0.currency == currency })
         else {
        continue
      }
      
      let converted = rateConverter.convert(
        amount: jettonBalance.amount.quantity,
        amountFractionLength: jettonBalance.amount.jettonInfo.fractionDigits,
        rate: jettonRates
      )
      items.append(Item(amount: converted.amount, fractionDigits: converted.fractionLength))
      maximumFractionDigits = max(converted.fractionLength, maximumFractionDigits)
    }
    
    var totalSum = BigUInt("0")
    for item in items {
      if item.fractionDigits < maximumFractionDigits {
        let countToExtend = maximumFractionDigits - item.fractionDigits
        let amountToMultiply = BigUInt(stringLiteral: "1" + String(repeating: "0", count: countToExtend))
        let extendedAmount = item.amount * amountToMultiply
        totalSum += extendedAmount
      } else {
        totalSum += item.amount
      }
    }
    
    let formattedTotalAmount = amountFormatter.formatAmountWithoutFractionIfThousand(
      totalSum,
      fractionDigits: maximumFractionDigits,
      maximumFractionDigits: 2,
      currency: currency
    )
                                       
    return formattedTotalAmount
  }
  
  func mapTon(tonBalance: TonBalance,
              tonRates: [Rates.Rate],
              currency: Currency) -> WalletBalanceModel.Item {
    let bigUIntAmount = BigUInt(tonBalance.amount)
    let amount = amountFormatter.formatAmount(
      bigUIntAmount,
      fractionDigits: TonInfo.fractionDigits,
      maximumFractionDigits: 2
    )
    
    var price: String?
    var convertedAmount: String?
    var diff: String?
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
      price = decimalAmountFormatter.format(
        amount: rate.rate,
        currency: currency
      )
      diff = rate.diff24h == "0" ? nil : rate.diff24h
    }
    
    return WalletBalanceModel.Item(
      identifier: .tonIdentifier,
      token: .ton,
      image: .ton,
      title: TonInfo.name,
      price: price,
      rateDiff: diff,
      amount: amount,
      convertedAmount: convertedAmount,
      verification: .whitelist)
  }
  
  func mapJettons(jettonsBalance: [JettonBalance],
                  jettonsRates: [Rates.JettonRate],
                  currency: Currency) -> [WalletBalanceModel.Item] {
    return jettonsBalance.map { jettonBalance in
      let jettonRates = jettonsRates.first(where: { $0.jettonInfo == jettonBalance.amount.jettonInfo })
      return mapJetton(
        jettonAmount: jettonBalance.amount,
        jettonRates: jettonRates,
        currency: currency
      )
    }
  }
  
  func mapJetton(jettonAmount: JettonAmount,
                 jettonRates: Rates.JettonRate?,
                 currency: Currency) -> WalletBalanceModel.Item {
    let amount = amountFormatter.formatAmount(
      jettonAmount.quantity,
      fractionDigits: jettonAmount.jettonInfo.fractionDigits,
      maximumFractionDigits: 2
    )
    
    var price: String?
    var convertedAmount: String?
    var diff: String?
    if let rate = jettonRates?.rates.first(where: { $0.currency == currency }) {
      let converted = rateConverter.convert(
        amount: jettonAmount.quantity,
        amountFractionLength: jettonAmount.jettonInfo.fractionDigits,
        rate: rate
      )
      convertedAmount = amountFormatter.formatAmount(
        converted.amount,
        fractionDigits: converted.fractionLength,
        maximumFractionDigits: 2,
        currency: currency
      )
      price = decimalAmountFormatter.format(
        amount: rate.rate,
        currency: currency
      )
      diff = rate.diff24h == "0" ? nil : rate.diff24h
    }
    return WalletBalanceModel.Item(
      identifier: jettonAmount.jettonInfo.address.toRaw(),
      token: .jetton(jettonAmount.jettonInfo),
      image: .url(jettonAmount.jettonInfo.imageURL),
      title: jettonAmount.jettonInfo.symbol ?? jettonAmount.jettonInfo.name,
      price: price,
      rateDiff: diff,
      amount: amount,
      convertedAmount: convertedAmount,
      verification: jettonAmount.jettonInfo.verification
    )
  }
}

private extension String {
  static let tonIdentifier = UUID().uuidString
}
