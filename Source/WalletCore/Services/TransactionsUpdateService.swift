//
//  TransactionsUpdatePublishService.swift
//
//
//  Created by Grigory on 18.9.23..
//

import Foundation
import TonStreamingAPI
import EventSource
import TonSwift

struct TransactionUpdate {
    let accountAddress: Address
    let lt: Int64
    let txHash: String
}

enum TransactionsUpdateServiceState {
    case connecting
    case connected
    case closed(Swift.Error?)
}

protocol TransactionsUpdateService {
    typealias StateUpdateStream = AsyncStream<TransactionsUpdateServiceState>
    typealias EventStream = AsyncStream<TransactionUpdate>
    
    var state: TransactionsUpdateServiceState { get async }
    func start(addresses: [Address]) async
    func stop() async
    func getStateObservationStream() async -> StateUpdateStream
    func getEventStream() async -> EventStream
}

actor TransactionsUpdateServiceImplementation: TransactionsUpdateService {
    private let streamingAPI: TonStreamingAPI.Client
    
    private var task: Task<(), Never>?
    private(set) var state: TransactionsUpdateServiceState = .closed(nil) {
        didSet {
            didUpdateState()
        }
    }
    private var stateUpdateObserversContinuations = [UUID: StateUpdateStream.Continuation]()
    private var eventObservsersContinuations = [UUID: EventStream.Continuation]()
    
    init(streamingAPI: TonStreamingAPI.Client) {
        self.streamingAPI = streamingAPI
    }
    
    func start(addresses: [Address]) {
        let addressesStrings = addresses.map { $0.toRaw() }
        let task = Task {
            do {
                state = .connecting
                let stream: AsyncThrowingStream<EventSource.Transaction, Swift.Error> = try await EventSource.eventSource {
                    try await streamingAPI.getTransactions(query: .init(accounts: addressesStrings))
                        .ok.body.text_event_hyphen_stream
                }
                state = .connected
                for try await transaction in stream {
                    guard let accountAddress = try? Address.parse(transaction.accountId) else { continue }
                    let transactionUpdate = TransactionUpdate(
                        accountAddress: accountAddress,
                        lt: transaction.lt,
                        txHash: transaction.txHash
                    )
                    didReceiveTransactionUpdate(transactionUpdate)
                }
                guard !Task.isCancelled else { return }
                start(addresses: addresses)
            } catch {
                state = .closed(error)
            }
        }
        self.task = task
    }
    
    func stop() {
        task?.cancel()
        task = nil
        state = .closed(nil)
    }
    
    func getStateObservationStream() -> StateUpdateStream {
        let uuid = UUID()
        return StateUpdateStream { continuation in
            stateUpdateObserversContinuations[uuid] = continuation
            continuation.yield(state)
            continuation.onTermination = { [weak self] termination in
                guard let self = self else { return }
                Task { await self.removeStateUpdateObserver(uuid: uuid) }
            }
        }
    }
    
    func getEventStream() -> EventStream {
        let uuid = UUID()
        return EventStream { continuation in
            eventObservsersContinuations[uuid] = continuation
            continuation.onTermination = { [weak self] termination in
                guard let self = self else { return }
                Task { await self.removeEventObserver(uuid: uuid) }
            }
        }
    }
}

private extension TransactionsUpdateServiceImplementation {
    func removeStateUpdateObserver(uuid: UUID) {
        stateUpdateObserversContinuations.removeValue(forKey: uuid)
    }
    
    func removeEventObserver(uuid: UUID) {
        eventObservsersContinuations.removeValue(forKey: uuid)
    }
    
    func didUpdateState() {
        stateUpdateObserversContinuations.values.forEach { $0.yield(state) }
    }
    
    func didReceiveTransactionUpdate(_ transactionUpdate: TransactionUpdate) {
        eventObservsersContinuations.values.forEach { $0.yield(transactionUpdate) }
    }
}
