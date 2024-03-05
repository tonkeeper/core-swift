import Foundation
import TonSwift

public struct Recipient {
  public enum RecipientAddress {
    case friendly(FriendlyAddress)
    case raw(Address)
    case domain(Domain)
  }
  
  public let recipientAddress: RecipientAddress
  public let isKnownAccount: Bool
}
