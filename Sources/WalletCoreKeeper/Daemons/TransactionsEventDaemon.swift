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
    public let accountAddress: Address
    public let lt: Int64
    public let txHash: String
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

final class TransactionsEventDaemonImplementation: TransactionsEventDaemon {
    final class WeakObserverBox {
        weak var observer: TransactionsEventDaemonObserver?
        init(observer: TransactionsEventDaemonObserver) {
            self.observer = observer
        }
    }
    
    private let streamingAPI: TonStreamingAPI.Client
    private var jsonDecoder = JSONDecoder()
    private var retryTimer: Timer?
    
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
        retryTimer?.invalidate()
    }
    
    @MainActor
    func start(addresses: [Address]) {
        switch state {
        case .connecting(let connectingAddresses):
            guard addresses != connectingAddresses else { return }
            connect(addresses: addresses)
        case .connected(let connectedAddresses):
            guard addresses != connectedAddresses else { return }
            connect(addresses: addresses)
        case .disconnected:
            connect(addresses: addresses)
        case .noConnection:
            connect(addresses: addresses)
        }
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
        self.retryTimer?.invalidate()
        self.retryTimer = nil
        let task = Task {
            let addressesStrings = addresses.map { $0.toRaw() }
            do {
                await MainActor.run { self.state = .connecting(addresses: addresses) }
                let stream = try await EventSource.eventSource {
                    let response = try await self.streamingAPI.getTransactions(
                        query: .init(accounts: addressesStrings)
                    )
                    return try response.ok.body.text_event_hyphen_stream
                }
                if Task.isCancelled {
                    return
                }
                await MainActor.run { self.state = .connected(addresses: addresses) }
                for try await events in stream {
                    handleReceivedEvents(events)
                }
                await MainActor.run { self.state = .disconnected }
                guard !Task.isCancelled else {
                    return
                }
                connect(addresses: addresses)
            } catch {
                if error.isNoConnectionError {
                    await MainActor.run { self.state = .noConnection }
                } else {
                    await MainActor.run {
                        let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { [weak self] _ in
                            guard let self = self else { return }
                            Task {
                                await self.start(addresses: addresses)
                            }
                        })
                        self.retryTimer = timer
                        RunLoop.current.add(timer, forMode: .common)
                    }
                    await MainActor.run { self.state = .disconnected }
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
