import Foundation

public enum WalletVersion: String {
    case v3R1, v3R2, v4R1, v4R2
}

public struct WalletAddress {
    let friendlyAddress: String
    let rawAddress: String
    let version: WalletVersion
}
