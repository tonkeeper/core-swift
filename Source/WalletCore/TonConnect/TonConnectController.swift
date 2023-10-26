//
//  TonConnectController.swift
//  
//
//  Created by Grigory Serebryanyy on 18.10.2023.
//

import Foundation
import TonSwift
import TonConnectAPI

public actor TonConnectController {
    public struct PopUpModel {
        public let name: String
        public let host: String?
        public let wallet: String
        public let revision: String
        public let appImageURL: URL?
    }
    
    private let parameters: TCParameters
    private let manifest: TonConnectManifest
    private let apiClient: TonConnectAPI.Client
    private let walletProvider: WalletProvider
    private let keychainManager: KeychainManager
    private let keychainGroup: String
    
    init(parameters: TCParameters,
         manifest: TonConnectManifest,
         apiClient: TonConnectAPI.Client,
         walletProvider: WalletProvider,
         keychainManager: KeychainManager,
         keychainGroup: String) {
        self.parameters = parameters
        self.manifest = manifest
        self.apiClient = apiClient
        self.walletProvider = walletProvider
        self.keychainManager = keychainManager
        self.keychainGroup = keychainGroup
    }
    
    nonisolated
    public func getPopUpModel() -> PopUpModel {
        let walletAddress: String
        let revision: String
        do {
            let contractBuilder = WalletContractBuilder()
            let wallet = try walletProvider.activeWallet
            let contract = try contractBuilder.walletContract(
                with: try wallet.publicKey,
                contractVersion: wallet.contractVersion
            )
            walletAddress = try contract.address().toShortString(bounceable: false)
            revision = wallet.contractVersion.rawValue
        } catch {
            walletAddress = ""
            revision = ""
        }
        
        return PopUpModel(
            name: manifest.name,
            host: manifest.url.host,
            wallet: walletAddress,
            revision: revision,
            appImageURL: manifest.iconUrl
        )
    }
    
    public func connect() async throws {
        let contractBuilder = WalletContractBuilder()
        let wallet = try walletProvider.activeWallet
        let contract = try contractBuilder.walletContract(
            with: try wallet.publicKey,
            contractVersion: wallet.contractVersion
        )
        let mnemonicVault = try KeychainMnemonicVault(
            keychainManager: keychainManager,
            walletID: wallet.identity.id(),
            keychainGroup: keychainGroup)
        let mnemonic = try mnemonicVault.loadValue(key: try wallet.publicKey)
        let keyPair = try Mnemonic.mnemonicToPrivateKey(mnemonicArray: mnemonic)
        
        let sessionCrypto = try TonConnectSessionCrypto()
        
        let replyItems = createConnectItemReplyItems(
            parameters.requestPayload.items,
            address: try contract.address(),
            network: wallet.identity.network,
            publicKey: try wallet.publicKey,
            stateInit: contract.stateInit,
            privateKey: keyPair.privateKey)
        
        let connectEventSuccess = TonConnectEventSuccess(
            payload: .init(items: replyItems.map { .init(value: $0) },
                           device: .init())
        )
        
        let responseData = try JSONEncoder().encode(connectEventSuccess)
        guard let receiverPublicKey = Data(hex: parameters.clientId) else { return }
        
        let response = try sessionCrypto.encrypt(
            message: responseData,
            receiverPublicKey: receiverPublicKey
        )
        let base64body = response.base64EncodedString()
        let resp = try await apiClient.message(
            query: .init(client_id: sessionCrypto.sessionId,
                         to: parameters.clientId, ttl: 300),
            body: .plainText(.init(stringLiteral: base64body))
        )
        _ = try resp.ok.body.json
    }
}

private extension TonConnectController {
    func createConnectItemReplyItems(_ items: [TCRequestPayload.Item],
                                     address: TonSwift.Address,
                                     network: Network,
                                     publicKey: TonSwift.PublicKey,
                                     stateInit: StateInit,
                                     privateKey: TonSwift.PrivateKey) -> [TonConnectItemReply] {
        return items.compactMap { item in
            switch item {
            case .tonAddress:
                return TCTonAddressItemReply(
                    address: address,
                    network: network,
                    publicKey: publicKey,
                    walletStateInit: stateInit)
            case .tonProof(let payload):
                return TCTonProofItemReply(
                    address: address,
                    domain: manifest.host,
                    payload: payload,
                    privateKey: privateKey
                )
            case .unknown:
                return nil
            }
        }
    }
}
