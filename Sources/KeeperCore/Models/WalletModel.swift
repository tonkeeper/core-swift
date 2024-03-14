import Foundation

public struct WalletModel: Equatable {
  public let identifier: String
  public let label: String
  public let tag: String
  public let emoji: String
  public let tintColor: WalletTintColor
  
  public var emojiLabel: String {
    "\(emoji) \(label)"
  }
  
  public static func == (lhs: WalletModel, rhs: WalletModel) -> Bool {
    lhs.identifier == rhs.identifier
  }
}

extension Wallet {
  var model: WalletModel {
    WalletModel(
      identifier: id,
      label: metaData.label,
      tag: "",
      emoji: metaData.emoji,
      tintColor: metaData.tintColor
    )
  }
}
