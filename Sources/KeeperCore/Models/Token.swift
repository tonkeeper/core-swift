import Foundation

public enum Token: Equatable {
  case ton
  case jetton(JettonInfo)
}
