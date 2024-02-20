import Foundation
import TonSwift

public enum Deeplink {
  case ton(TonDeeplink)
  case tonConnect(TonConnectDeeplink)
  
  public var string: String {
    switch self {
    case .ton(let tonDeeplink):
      return tonDeeplink.string
    case .tonConnect(let tonConnectDeeplink):
      return tonConnectDeeplink.string
    }
  }
}

public enum TonDeeplink {
  case transfer(recipient: String)
  
  public var string: String {
    let ton = "ton://"
    switch self {
    case let .transfer(recipient):
      return "\(ton)transfer/\(recipient)"
    }
  }
}

public struct TonConnectDeeplink {
  let string: String
}
