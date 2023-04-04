import Foundation

public struct AccountState {
    public static let `default` = AccountState(publicKeys: [], activePublicKey: nil)
    
    public let publicKeys: [String]
    public let activePublicKey: String?
}
