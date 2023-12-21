import Foundation

struct WalletBalanceState: LocalStorable {
    typealias KeyType = String
    
    var key: String {
        balance.walletAddress.toRaw()
    }
    
    let date: Date
    let balance: WalletBalance
}
