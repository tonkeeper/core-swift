import Foundation
import TonSwift

public struct DeeplinkGenerator {
  public func generateTransferDeeplink(with addressString: String) throws -> TonDeeplink {
    return TonDeeplink.transfer(recipient: addressString)
  }
}
