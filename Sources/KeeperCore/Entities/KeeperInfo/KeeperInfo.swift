import Foundation

/// Represents the entire state of the application install
public struct KeeperInfo {
  /// Keeper contains multiple wallets
  let wallets: [Wallet]
  
  /// Currently selected wallet
  let currentWallet: Wallet
  
  /// Common pin/faceid settings
  let securitySettings: SecuritySettings
  
  ///
  let assetsPolicy: AssetsPolicy
  let appCollection: AppCollection
}

extension KeeperInfo: Codable {
  enum CodingKeys: String, CodingKey {
    case wallets
    case currentWallet
    case securitySettings
    case assetsPolicy
    case appCollection
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    wallets = try container.decode([Wallet].self, forKey: .wallets)
    securitySettings = try container.decode(SecuritySettings.self, forKey: .securitySettings)
    assetsPolicy = try container.decode(AssetsPolicy.self, forKey: .assetsPolicy)
    appCollection = try container.decode(AppCollection.self, forKey: .appCollection)
    
    if let currentWalletIdentity = try? container.decode(WalletIdentity.self, forKey: .currentWallet),
       let currentWallet = wallets.first(where: { $0.identity == currentWalletIdentity }) {
      self.currentWallet = currentWallet
    } else {
      let currentWallet = try container.decode(Wallet.self, forKey: .currentWallet)
      self.currentWallet = currentWallet
    }
  }
}
