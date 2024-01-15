import Foundation

public struct WalletMetaData: Codable {
  public let label: String
  public let colorIdentifier: String
  public let emoji: String
  
  public init(label: String,
              colorIdentifier: String,
              emoji: String) {
    self.label = label
    self.colorIdentifier = colorIdentifier
    self.emoji = emoji
  }
}
