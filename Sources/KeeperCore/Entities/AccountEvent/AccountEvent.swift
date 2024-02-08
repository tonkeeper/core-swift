import Foundation

struct AccountEvent: Codable {
  let eventId: String
  let timestamp: TimeInterval
  let account: WalletAccount
  let isScam: Bool
  let isInProgress: Bool
  let fee: Int64
  let actions: [AccountEventAction]
}
