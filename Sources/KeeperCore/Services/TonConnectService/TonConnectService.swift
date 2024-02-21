import Foundation
import TonConnectAPI
import TonSwift

enum TonConnectServiceError: Swift.Error {
  case incorrectUrl
  case manifestLoadFailed
  case unsupportedWalletKind(walletKind: WalletKind)
}

protocol TonConnectService {
  func loadTonConnectConfiguration(with deeplink: TonConnectDeeplink) async throws -> (TonConnectParameters, TonConnectManifest)
  func connect(wallet: Wallet,
               parameters: TonConnectParameters,
               manifest: TonConnectManifest) async throws
}

final class TonConnectServiceImplementation: TonConnectService {
  
  private let urlSession: URLSession
  private let apiClient: TonConnectAPI.Client
  private let mnemonicRepository: WalletMnemonicRepository
  private let tonConnectAppsVault: TonConnectAppsVault
  
  init(urlSession: URLSession,
       apiClient: TonConnectAPI.Client,
       mnemonicRepository: WalletMnemonicRepository,
       tonConnectAppsVault: TonConnectAppsVault) {
    self.urlSession = urlSession
    self.apiClient = apiClient
    self.mnemonicRepository = mnemonicRepository
    self.tonConnectAppsVault = tonConnectAppsVault
  }
  
  func loadTonConnectConfiguration(with deeplink: TonConnectDeeplink) async throws -> (TonConnectParameters, TonConnectManifest) {
    let parameters = try parseTonConnectDeeplink(deeplink)
    do {
      let manifest = try await loadManifest(url: parameters.requestPayload.manifestUrl)
      return (parameters, manifest)
    } catch {
      throw TonConnectServiceError.manifestLoadFailed
    }
  }
  
  func connect(wallet: Wallet, 
               parameters: TonConnectParameters,
               manifest: TonConnectManifest) async throws {
    guard wallet.isRegular else { throw
      TonConnectServiceError.unsupportedWalletKind(
        walletKind: wallet.identity.kind
      )
    }
    let mnemonic = try mnemonicRepository.getMnemonic(forWallet: wallet)
    let keyPair = try TonSwift.Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonic.mnemonicWords)
    let privateKey = keyPair.privateKey
    
    let sessionCrypto = try TonConnectSessionCrypto()
    let body = try TonConnectResponseBuilder
        .buildConnectEventSuccesResponse(
            requestPayloadItems: parameters.requestPayload.items,
            wallet: wallet,
            sessionCrypto: sessionCrypto,
            walletPrivateKey: privateKey,
            manifest: manifest,
            clientId: parameters.clientId
        )
    let resp = try await apiClient.message(
        query: .init(client_id: sessionCrypto.sessionId,
                     to: parameters.clientId, ttl: 300),
        body: .plainText(.init(stringLiteral: body))
    )
    _ = try resp.ok.body.json
    
    let tonConnectApp = TonConnectApp(
      clientId: parameters.clientId,
      manifest: manifest,
      keyPair: sessionCrypto.keyPair
    )
    
    let key = try wallet.address.toRaw()
    if let apps = try? tonConnectAppsVault.loadValue(key: key) {
      try tonConnectAppsVault.saveValue(apps.addApp(tonConnectApp), for: key)
    } else {
      let apps = TonConnectApps(apps: [tonConnectApp])
      try tonConnectAppsVault.saveValue(apps.addApp(tonConnectApp), for: key)
    }
  }
}

private extension TonConnectServiceImplementation {
  func parseTonConnectDeeplink(_ deeplink: TonConnectDeeplink) throws -> TonConnectParameters {
    guard
      let url = URL(string: deeplink.string),
      let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
      components.scheme == .tcScheme,
      let queryItems = components.queryItems,
      let versionValue = queryItems.first(where: { $0.name == .versionKey })?.value,
      let version = TonConnectParameters.Version(rawValue: versionValue),
      let clientId = queryItems.first(where: { $0.name == .clientIdKey })?.value,
      let requestPayloadValue = queryItems.first(where: { $0.name == .requestPayloadKey })?.value,
      let requestPayloadData = requestPayloadValue.data(using: .utf8),
      let requestPayload = try? JSONDecoder().decode(TonConnectRequestPayload.self, from: requestPayloadData)
    else {
      throw TonConnectServiceError.incorrectUrl
    }
    
    return TonConnectParameters(
      version: version,
      clientId: clientId,
      requestPayload: requestPayload)
  }
  
  func loadManifest(url: URL) async throws -> TonConnectManifest {
    let (data, _) = try await urlSession.data(from: url)
    let jsonDecoder = JSONDecoder()
    return try jsonDecoder.decode(TonConnectManifest.self, from: data)
  }
}

private extension String {
  static let tcScheme = "tc"
  static let versionKey = "v"
  static let clientIdKey = "id"
  static let requestPayloadKey = "r"
}
