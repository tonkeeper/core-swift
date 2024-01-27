import Foundation

public struct WalletBalanceModel {
  public let total: String
  public let items: [Item]
}

public extension WalletBalanceModel {
  struct Item {
    public enum Image {
      case ton
      case url(URL?)
    }
    public let identifier: String
    public let image: Image
    public let title: String
    public let price: String?
    public let rateDiff: String?
    public let amount: String?
    public let convertedAmount: String?
  }
}
