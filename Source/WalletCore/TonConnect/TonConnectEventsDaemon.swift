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
                                                 message: TonConnectMessage)
}

public final class TonConnectEventsDaemon {
    struct TonConnectEventsDaemonObserverWrapper {
        weak var observer: TonConnectEventsDaemonObserver?
    }
    
    struct TonConnectWalletLastEvent: Codable, LocalStorable {
        typealias KeyType = String
        var key: String { walletId }
        
        let walletId: String
        let lastEventId: String?
    }
    
    private let walletProvider: WalletProvider
    private let appsVault: TonConnectAppsVault
    private let apiClient: TonConnectAPI.Client
    private let localRepository: any LocalRepository<TonConnectWalletLastEvent>
    
    private var task: Task<Void, Error>?
    
    private var observers = [TonConnectEventsDaemonObserverWrapper]()
    private var jsonDecoder = JSONDecoder()
    
    init(walletProvider: WalletProvider,
         appsVault: TonConnectAppsVault,
         apiClient: TonConnectAPI.Client,
         localRepository: any LocalRepository<TonConnectWalletLastEvent>) {
        self.walletProvider = walletProvider
        self.appsVault = appsVault
        self.apiClient = apiClient
        self.localRepository = localRepository
    }
    
    public func startEventsObserving() {
        guard task == nil else { return }
        let task = Task {
            let wallet = try walletProvider.activeWallet
            let apps = (try? appsVault.loadValue(key: wallet)) ?? TonConnectApps(apps: [])
            let appsClientIds = apps.apps.map { $0.keyPair.publicKey.hexString }
            let errorParser = EventSourceDecodableErrorParser<TonConnectError>()
            let stream = try await EventSource.eventSource({
                let lastEventId = try? localRepository.load(key: try wallet.identity.id().string).lastEventId
                let response = try await self.apiClient.events(
                    query: .init(client_id: appsClientIds, last_event_id: lastEventId)
                )
                return try response.ok.body.text_event_hyphen_stream
            }, errorParser: errorParser)
            for try await events in stream {
                try handleEventSourceEvents(
                    events,
                    walletIdentity: try wallet.identity.id().string,
                    apps: apps)
            }
            guard !Task.isCancelled else { return }
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
    func handleEventSourceEvents(_ events: [EventSource.Event],
                                 walletIdentity: String,
                                 apps: TonConnectApps) throws {
        guard let event = events.last(where: { $0.event == "message" }),
              let data = event.data?.data(using: .utf8),
              let tcEvent = try? jsonDecoder.decode(TonConnectEvent.self, from: data) else {
            return
        }
        try localRepository.save(
            item: .init(walletId: walletIdentity,
                        lastEventId: event.id)
        )
        try? handleEvent(tcEvent, apps: apps)
    }
    
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
