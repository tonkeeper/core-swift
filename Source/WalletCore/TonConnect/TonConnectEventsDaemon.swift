//
//  TonConnectEventsDaemon.swift
//  
//
//  Created by Grigory Serebryanyy on 26.10.2023.
//

import Foundation
import TonConnectAPI
import EventSource
import TonSwift

public protocol TonConnectEventsDaemonObserver: AnyObject {
    func tonConnectEventsDaemonDidReceiveMessage(_ daemon: TonConnectEventsDaemon,
                                                 message: TonConnectEventsDaemon.TonConnectMessage)
}

public final class TonConnectEventsDaemon {
    struct TonConnectEventsDaemonObserverWrapper {
        weak var observer: TonConnectEventsDaemonObserver?
    }
    
    struct TonConnectEvent: Decodable {
        let from: String
        let message: String
    }
    
    public struct TonConnectMessage: Decodable {
        enum Method: String, Decodable {
            case sendTransaction
        }
        
        struct Param: Decodable {
            let messages: [Message]
            let validUntil: TimeInterval
            let from: Address
            
            enum CodingKeys: String, CodingKey {
                case messages
                case validUntil = "valid_until"
                case from
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                messages = try container.decode([Message].self, forKey: .messages)
                validUntil = try container.decode(TimeInterval.self, forKey: .validUntil)
                from = try Address.parse(try container.decode(String.self, forKey: .from))
            }
        }
        
        struct Message: Decodable {
            let address: Address
            let amount: Int64
            
            enum CodingKeys: String, CodingKey {
                case address
                case amount
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                address = try Address.parse(try container.decode(String.self, forKey: .address))
                amount = Int64(try container.decode(String.self, forKey: .amount)) ?? 0
            }
        }
        
        let method: Method
        let params: [Param]
        
        enum CodingKeys: String, CodingKey {
            case method
            case params
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            method = try container.decode(Method.self, forKey: .method)
            let paramsArray = try container.decode([String].self, forKey: .params)
            let jsonDecoder = JSONDecoder()
            params = paramsArray.compactMap {
                guard let data = $0.data(using: .utf8) else { return nil }
                return try? jsonDecoder.decode(Param.self, from: data)
            }
        }
    }
    
    struct TonConnectError: Swift.Error, Decodable {
        let statusCode: Int
        let message: String
    }
    
    private let walletProvider: WalletProvider
    private let appsVault: TonConnectAppsVault
    private let apiClient: TonConnectAPI.Client
    
    private var task: Task<Void, Error>?
    
    private var observers = [TonConnectEventsDaemonObserverWrapper]()
    
    init(walletProvider: WalletProvider,
         appsVault: TonConnectAppsVault,
         apiClient: TonConnectAPI.Client) {
        self.walletProvider = walletProvider
        self.appsVault = appsVault
        self.apiClient = apiClient
    }
    
    public func startEventsObserving() {
        let task = Task {
            let wallet = try walletProvider.activeWallet
            let apps = try appsVault.loadValue(key: wallet)
            let appsClientIds = apps.apps.map { $0.keyPair.publicKey.hexString }
            let errorParser = EventSourceDecodableErrorParser<TonConnectError>()
            let stream: AsyncThrowingStream<TonConnectEvent, Swift.Error> = try await EventSource.eventSource({
                let response = try await self.apiClient.events(query: .init(client_id: appsClientIds))
                return try response.ok.body.text_event_hyphen_stream
            }, errorParser: errorParser)
            for try await event in stream {
                try? handleEvent(event, apps: apps)
            }
            startEventsObserving()
        }
        self.task = task
    }
    
    public func stopEventsObserving() {
        task?.cancel()
        task = nil
    }
    
    public func addObserver(_ observer: TonConnectEventsDaemonObserver) {
        var observers = observers.filter { $0.observer != nil }
        observers.append(.init(observer: observer))
        self.observers = observers
    }
    
    public func removeObserver(_ observer: TonConnectEventsDaemonObserver) {
        observers = observers.filter { $0.observer !== observer }
    }
}

extension TonConnectEventsDaemon: TonConnectControllerObserver {
    func tonConnectControllerDidUpdateApps(_ controller: TonConnectController) {
        stopEventsObserving()
        startEventsObserving()
    }
}

private extension TonConnectEventsDaemon {
    func handleEvent(_ event: TonConnectEvent,
                     apps: TonConnectApps) throws {
        guard let eventApp = apps.apps.first(where: { $0.clientId == event.from }) else { return }
        let sessionCrypto = try TonConnectSessionCrypto(privateKey: eventApp.keyPair.privateKey)
        guard let senderPublicKey = Data(hex: eventApp.clientId),
              let message = Data(base64Encoded: event.message) else { return }
        let decryptedMessage = try sessionCrypto
            .decrypt(
                message: message,
                senderPublicKey: senderPublicKey
            )
        notifyObservers(
            message: try JSONDecoder()
                .decode(TonConnectMessage.self,
                        from: decryptedMessage)
        )
    }
    
    func notifyObservers(message: TonConnectMessage) {
        observers = observers.filter { $0.observer != nil }
        observers.forEach { $0.observer?
                .tonConnectEventsDaemonDidReceiveMessage(
                    self,
                    message: message
                ) }
    }
}
