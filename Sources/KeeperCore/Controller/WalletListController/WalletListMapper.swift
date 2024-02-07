import Foundation
import BigInt

struct WalletListMapper {
  
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
  
  func mapWalletModel(wallet: Wallet,
                      balance: String,
                      rates: Rates) -> WalletListController.WalletModel {
    let identifier = (try? wallet.identity.id().string) ?? UUID().uuidString
    let name = {
      wallet.metaData.label.isEmpty ? "Wallet" : wallet.metaData.label
    }()
    let tag: String? = {
      if wallet.isRegular {
        switch wallet.isTestnet {
        case true: return "TESTNET"
        case false: return nil
        }
      }
      if wallet.isWatchonly {
        return "WATCH ONLY"
      }
      if wallet.isExternal {
        return "EXTERNAL"
      }
      return nil
    }()
    let emoji: String = {
      wallet.metaData.emoji.isEmpty ? "😀" : wallet.metaData.emoji
    }()
    let colorIdentifier: String = {
      wallet.metaData.colorIdentifier.isEmpty ? "Color1" : wallet.metaData.colorIdentifier
    }()
    
    return WalletListController.WalletModel(
      identifier: identifier,
      name: name,
      tag: tag,
      emoji: emoji,
      colorIdentifier: colorIdentifier,
      balance: balance
    )
  }
  
  func mapTotalBalance(balance: Balance,
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
        amount: balance.tonBalance.amount,
        amountFractionLength: TonInfo.fractionDigits,
        rate: tonRate
      )
      items.append(Item(amount: converted.amount, fractionDigits: converted.fractionLength))
      maximumFractionDigits = converted.fractionLength
    }
    
    // Jettons
    for jettonBalance in balance.jettonsBalance {
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
}
