import Foundation
import TonStreamingAPI
import EventSource
import TonSwift
import os

public enum TransactionsEventDaemonState {
    case connecting(addresses: [Address])
    case connected(addresses: [Address])
    case disconnected
    case noConnection
}

public struct TransactionsEventDaemonTransaction {
    let accountAddress: Address
    let lt: Int64
    let txHash: String
}

public protocol TransactionsEventDaemon: AnyObject {
    var state: TransactionsEventDaemonState { get async }
    
    func start(addresses: [Address]) async
    func stop() async
    
    func addObserver(_ observer: TransactionsEventDaemonObserver)
    func removeObserver(_ observer: TransactionsEventDaemonObserver)
}

public protocol TransactionsEventDaemonObserver: AnyObject {
    func didUpdateState(_ state: TransactionsEventDaemonState)
    func didReceiveTransaction(_ transaction: TransactionsEventDaemonTransaction)
}

actor TransactionsEventDaemonImplementation: TransactionsEventDaemon {
    final class WeakObserverBox {
        weak var observer: TransactionsEventDaemonObserver?
        init(observer: TransactionsEventDaemonObserver) {
            self.observer = observer
        }
    }
    
    private let streamingAPI: TonStreamingAPI.Client
    private var jsonDecoder = JSONDecoder()
    
    var state: TransactionsEventDaemonState = .disconnected {
        didSet {
            notifyObservers(with: state)
        }
    }
    private var task: Task<Void, Never>?
    
    nonisolated
    private lazy var observers = [WeakObserverBox]()
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "",
                                     category: String(describing: self))
    
    init(streamingAPI: TonStreamingAPI.Client) {
        self.streamingAPI = streamingAPI
    }
    
    deinit {
        task?.cancel()
    }
    
    func start(addresses: [Address]) {
        connect(addresses: addresses)
    }
    
    func stop() {
        task?.cancel()
        task = nil
    }
    
    nonisolated
    func addObserver(_ observer: TransactionsEventDaemonObserver) {
        guard !observers.contains(where: { $0.observer === observer }) else { return }
        observers.append(WeakObserverBox(observer: observer))
    }
    
    nonisolated
    func removeObserver(_ observer: TransactionsEventDaemonObserver) {
        observers = observers.filter { $0.observer !== observer }
    }
}

private extension TransactionsEventDaemonImplementation {
    func connect(addresses: [Address]) {
        let task = Task {
            let addressesStrings = addresses.map { $0.toRaw() }
            do {
                self.state = .connecting(addresses: addresses)
                let stream = try await EventSource.eventSource {
                    let response = try await self.streamingAPI.getTransactions(
                        query: .init(accounts: addressesStrings)
                    )
                    return try response.ok.body.text_event_hyphen_stream
                }
                if Task.isCancelled {
                    return
                }
                self.state = .connected(addresses: addresses)
                for try await events in stream {
                    handleReceivedEvents(events)
                }
                self.state = .disconnected
                guard !Task.isCancelled else {
                    return
                }
                connect(addresses: addresses)
            } catch {
                if error.isNoConnectionError {
                    self.state = .noConnection
                } else {
                    self.state = .disconnected
                    connect(addresses: addresses)
                }
            }
        }
        self.task = task
    }
    
    func handleReceivedEvents(_ events: [EventSource.Event]) {
        guard let messageEvent = events.last(where: { $0.event == "message" }),
              let eventData = messageEvent.data?.data(using: .utf8) else {
            return
        }
        do {
            let eventTransaction = try jsonDecoder.decode(EventSource.Transaction.self, from: eventData)
            let address = try Address.parse(eventTransaction.accountId)
            let transaction = TransactionsEventDaemonTransaction(
                accountAddress: address,
                lt: eventTransaction.lt,
                txHash: eventTransaction.txHash
            )
            notifyObservers(with: transaction)
        } catch {
            return
        }
    }
    
    func notifyObservers(with state: TransactionsEventDaemonState) {
        observers.forEach { $0.observer?.didUpdateState(state) }
    }
    
    func notifyObservers(with transaction: TransactionsEventDaemonTransaction) {
        observers.forEach { $0.observer?.didReceiveTransaction(transaction) }
    }
}
