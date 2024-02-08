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
    public enum Token {
      case ton
      case jetton(JettonInfo)
    }
    public let identifier: String
    public let token: Token
    public let image: Image
    public let title: String
    public let price: String?
    public let rateDiff: String?
    public let amount: String?
    public let convertedAmount: String?
    public let verification: JettonInfo.Verification
  }
}
