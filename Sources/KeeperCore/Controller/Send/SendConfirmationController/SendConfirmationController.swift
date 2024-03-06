import Foundation

public final class SendConfirmationController {
  private let recipient: Recipient
  private let sendItem: SendItem
  private let comment: String?
  
  init(recipient: Recipient, sendItem: SendItem, comment: String?) {
    self.recipient = recipient
    self.sendItem = sendItem
    self.comment = comment
  }
}
