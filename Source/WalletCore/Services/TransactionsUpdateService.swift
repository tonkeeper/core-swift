//
//  TransactionsUpdatePublishService.swift
//
//
//  Created by Grigory on 18.9.23..
//

import Foundation
import TonAPI
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
    private let streamingAPI: StreamingAPI
    
    private var task: Task<(), Never>?
    private(set) var state: TransactionsUpdateServiceState = .connecting {
        didSet {
            didUpdateState()
        }
    }
    private var stateUpdateObserversContinuations = [UUID: StateUpdateStream.Continuation]()
    private var eventObservsersContinuations = [UUID: EventStream.Continuation]()
    
    init(streamingAPI: StreamingAPI) {
        self.streamingAPI = streamingAPI
    }
    
    func start(addresses: [Address]) {
        task?.cancel()
        task = nil
        let addressesStrings = addresses.map { $0.toString() }
        let request = TransactionsStreamingRequest(accounts: addressesStrings)
        let task = Task {
            do {
                state = .connecting
                let (stream, _) = try await streamingAPI.stream(request: request)
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
    func checkIfNeedToReconnect(response: HTTPResponse) -> Bool {
        (200..<300).contains(response.statusCode)
    }
    
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
