import Foundation
import TonSwift
import BigInt

public struct Balance: Codable {
  public let tonBalance: TonBalance
  public let jettonsBalance: [JettonBalance]
}

public extension Balance {
  var isEmpty: Bool {
    tonBalance.amount == 0 && jettonsBalance.isEmpty
  }
}

public struct TonBalance: Codable {
  public let walletAddress: Address
  public let amount: Int64
}

public struct JettonBalance: Codable {
  public let walletAddress: Address
  public let amount: JettonAmount
}

public struct JettonAmount: Codable {
  public let jettonInfo: JettonInfo
  public let quantity: BigInt
}

public struct TonInfo {
  public static let name = "Toncoin"
  public static let symbol = "TON"
  public static let fractionDigits = 9
}

public struct JettonInfo: Codable, Equatable {
  public let address: Address
  public let fractionDigits: Int
  public let name: String
  public let symbol: String?
  public let imageURL: URL?
  
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.address == rhs.address
  }
}
