import Foundation

public typealias PublicKey = String
public typealias SecretKey = String
public typealias SharedKey = String

public struct WalletVoucher {
    let publicKey: PublicKey
    let secretKey: SecretKey
    let sharedKey: SharedKey
    let voucher: String
}

public struct WalletBackup {
    let revision: Int
    let voucher: WalletVoucher?
}
