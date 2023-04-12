import Foundation

public protocol WalletFavoriteProtocol {
    var name: String { get set }
    var address: String { get set }
}

public struct WalletFavorite {
    let name: String
    let address: String
}
