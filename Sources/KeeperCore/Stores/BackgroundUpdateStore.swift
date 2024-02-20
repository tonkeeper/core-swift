import Foundation
import TonStreamingAPI
import EventSource
import TonSwift
import OpenAPIRuntime

public protocol BackgroundUpdateStoreObserver: AnyObject {
  func didGetBackgroundUpdateStoreEvent(_ event: BackgroundUpdateStore.Event)
}

public actor BackgroundUpdateStore {
  public enum State {
    case connecting(addresses: [Address])
    case connected(addresses: [Address])
    case disconnected
    case noConnection
  }
  
  public struct UpdateEvent {
    public let accountAddress: Address
    public let lt: Int64
    public let txHash: String
  }
  
  public enum Event {
    case didUpdateState(State)
    case didReceiveUpdateEvent(UpdateEvent)
  }
  
  public var state: State = .disconnected {
    didSet {
      notifyObservers(with: .didUpdateState(state))
    }
  }
  
  private var task: Task<Void, Never>?
  private let jsonDecoder = JSONDecoder()
  private var retryTimer: Timer?
  
  private var observers = [BackgroundUpdateStoreObserverWrapper]()
  
  private let streamingAPI: TonStreamingAPI.Client
  
  init(streamingAPI: TonStreamingAPI.Client) {
    self.streamingAPI = streamingAPI
  }
  
  public func start(addresses: [Address]) async {
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
  
  public func stop() async {
    task?.cancel()
    task = nil
  }
  
  public func addObserver(_ observer: BackgroundUpdateStoreObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(
      BackgroundUpdateStoreObserverWrapper(observer: observer)
    )
  }
  
  public func removeObserver(_ observer: BackgroundUpdateStoreObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension BackgroundUpdateStore {
  func connect(addresses: [Address]) {
    self.retryTimer?.invalidate()
    self.retryTimer = nil
    
    self.task?.cancel()
    
    let runloop = RunLoop.current
    
    let task = Task {
      let rawAddresses = addresses.map { $0.toRaw() }.joined(separator: ",")
      
      do {
        self.state = .connecting(addresses: addresses)
        let stream = try await EventSource.eventSource {
          let response = try await self.streamingAPI.getTransactions(
            query: .init(accounts: [rawAddresses])
          )
          return try response.ok.body.text_event_hyphen_stream
        }
        
        guard !Task.isCancelled else { return }
        
        self.state = .connected(addresses: addresses)
        for try await events in stream {
          handleReceivedEvents(events)
        }
        self.state = .disconnected
        guard !Task.isCancelled else { return }
        connect(addresses: addresses)
      } catch {
        if error.isNoConnectionError {
          self.state = .noConnection
        } else {
          let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            Task {
              await self.start(addresses: addresses)
            }
          })
          self.retryTimer = timer
          runloop.add(timer, forMode: .common)
          self.state = .disconnected
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
      let updateEvent = UpdateEvent(
        accountAddress: address,
        lt: eventTransaction.lt,
        txHash: eventTransaction.txHash
      )
      notifyObservers(with: .didReceiveUpdateEvent(updateEvent))
    } catch {
      return
    }
  }
  
  struct BackgroundUpdateStoreObserverWrapper {
    weak var observer: BackgroundUpdateStoreObserver?
  }
  
  func notifyObservers(with event: Event) {
    observers.forEach { $0.observer?.didGetBackgroundUpdateStoreEvent(event) }
  }
  
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }
}

public extension Swift.Error {
  var isNoConnectionError: Bool {
    switch self {
    case let urlError as URLError:
      switch urlError.code {
      case URLError.Code.notConnectedToInternet,
        URLError.Code.networkConnectionLost:
        return true
      default: return false
      }
    case let clientError as OpenAPIRuntime.ClientError:
      return clientError.underlyingError.isNoConnectionError
    default:
      return false
    }
  }
}
