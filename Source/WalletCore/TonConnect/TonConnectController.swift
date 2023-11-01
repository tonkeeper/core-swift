//
//  TonConnectController.swift
//  
//
//  Created by Grigory Serebryanyy on 18.10.2023.
//

import Foundation
import TonSwift
import TonConnectAPI

protocol TonConnectControllerObserver: AnyObject {
    func tonConnectControllerDidUpdateApps(_ controller: TonConnectController)
}

public actor TonConnectController {
    struct TonConnectControllerObserverWrapper {
        weak var observer: TonConnectControllerObserver?
    }
    
    private var observers = [TonConnectControllerObserverWrapper]()
    
    public struct PopUpModel {
        public let name: String
        public let host: String?
        public let wallet: String
        public let revision: String
        public let appImageURL: URL?
    }
    
    private let parameters: TonConnectParameters
    private let manifest: TonConnectManifest
    private let apiClient: TonConnectAPI.Client
    private let walletProvider: WalletProvider
    private let appsVault: TonConnectAppsVault
    private let mnemonicVault: KeychainMnemonicVault
    
    nonisolated
    private var walletAddress: Address {
        get throws {
            let contractBuilder = WalletContractBuilder()
            let wallet = try walletProvider.activeWallet
            let contract = try contractBuilder.walletContract(
                with: try wallet.publicKey,
                contractVersion: wallet.contractVersion
            )
            return try contract.address()
        }
    }
    
    init(parameters: TonConnectParameters,
         manifest: TonConnectManifest,
         apiClient: TonConnectAPI.Client,
         walletProvider: WalletProvider,
         appsVault: TonConnectAppsVault,
         mnemonicVault: KeychainMnemonicVault) {
        self.parameters = parameters
        self.manifest = manifest
        self.apiClient = apiClient
        self.appsVault = appsVault
        self.walletProvider = walletProvider
        self.mnemonicVault = mnemonicVault
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
    
    nonisolated
    public func getWalletAddress() -> String {
        do {
            return try walletAddress.toString(bounceable: false)
        } catch {
            return ""
        }
    }
    
    public func connect() async throws {
        let wallet = try walletProvider.activeWallet
        let sessionCrypto = try TonConnectSessionCrypto()
        let body = try TonConnectResponseBuilder
            .buildConnectEventSuccesResponse(
                requestPayloadItems: parameters.requestPayload.items,
                wallet: wallet,
                sessionCrypto: sessionCrypto,
                mnemonicVault: mnemonicVault,
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
        
        let apps: TonConnectApps
        do {
            apps = try appsVault.loadValue(key: wallet)
        } catch {
            apps = TonConnectApps(apps: [tonConnectApp])
        }
        try appsVault.save(value: apps.addApp(tonConnectApp), for: wallet)
        notifyObservers()
    }
    
    func addObserver(_ observer: TonConnectControllerObserver) {
        var observers = observers.filter { $0.observer != nil }
        observers.append(.init(observer: observer))
        self.observers = observers
    }
    
    func removeObserver(_ observer: TonConnectControllerObserver) {
        observers = observers.filter { $0.observer !== observer }
    }
}

private extension TonConnectController {
    func notifyObservers() {
        observers = observers.filter { $0.observer != nil }
        observers.forEach { $0.observer?.tonConnectControllerDidUpdateApps(self) }
    }
}
