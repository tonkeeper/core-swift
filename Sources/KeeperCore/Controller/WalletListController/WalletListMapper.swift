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
                      balance: String) -> WalletListController.WalletModel {
    let identifier = (try? wallet.identity.identifier().string) ?? UUID().uuidString
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
  
  func mapTotalBalance(_ totalBalance: TotalBalance,
                       currency: Currency) -> String {
    amountFormatter.formatAmountWithoutFractionIfThousand(
      totalBalance.amount,
      fractionDigits: totalBalance.fractionalDigits,
      maximumFractionDigits: 2,
      currency: currency
    )
  }
}
