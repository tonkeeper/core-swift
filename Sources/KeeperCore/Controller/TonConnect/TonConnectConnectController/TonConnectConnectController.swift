import Foundation

public struct TonConnectConnectModel {
  public struct Wallet {
    public let name: String
    public let address: String?
    public let emoji: String
    public let colorIdentifier: String
  }
  
  public let name: String
  public let host: String
  public let address: String?
  public let wallet: Wallet
  public let appImageURL: URL?
}

public final class TonConnectConnectController {
  
  private let parameters: TonConnectParameters
  private let manifest: TonConnectManifest
  private let walletsStore: WalletsStore
  private let tonConnectAppsStore: TonConnectAppsStore
  
  init(parameters: TonConnectParameters, 
       manifest: TonConnectManifest,
       walletsStore: WalletsStore,
       tonConnectAppsStore: TonConnectAppsStore) {
    self.parameters = parameters
    self.manifest = manifest
    self.walletsStore = walletsStore
    self.tonConnectAppsStore = tonConnectAppsStore
  }
  
  public func getModel() -> TonConnectConnectModel {
    let wallet = walletsStore.activeWallet
    return TonConnectConnectModel(
      name: manifest.name,
      host: manifest.host,
      address: try? wallet.address.toString(bounceable: false),
      wallet: TonConnectConnectModel.Wallet(
        name: wallet.metaData.label,
        address: try? wallet.address.toShortString(bounceable: false),
        emoji: wallet.metaData.emoji,
        colorIdentifier: wallet.metaData.colorIdentifier
      ),
      appImageURL: manifest.iconUrl
    )
  }
  
  public func connect() async throws {
    try await tonConnectAppsStore.connect(
      wallet: walletsStore.activeWallet,
      parameters: parameters,
      manifest: manifest
    )
  }
  
  public func needToShowWalletPicker() -> Bool {
    !walletsStore.wallets.isEmpty
  }
}
