import Foundation

actor RatesStore {
  typealias Stream = AsyncStream<Void>
  
  private var continuations = [UUID: Stream.Continuation]()
  
  private let ratesService: RatesService
  
  init(ratesService: RatesService) {
    self.ratesService = ratesService
  }
  
  func loadRates(jettons: [JettonInfo]) {
    Task {
      _ = try await ratesService.loadRates(
        jettons: jettons,
        currencies: Currency.allCases
      )
      continuations.values.forEach { $0.yield() }
    }
  }
  
  func getRates(jettons: [JettonInfo]) -> Rates {
    return ratesService.getRates(jettons: jettons)
  }
  
  func updateStream() -> Stream {
    createUpdateStream()
  }
}

private extension RatesStore {
  func createUpdateStream() -> Stream {
    let uuid = UUID()
    return Stream { continuation in
      self.continuations[uuid] = continuation
      continuation.onTermination = { [weak self] termination in
        guard let self = self else { return }
        Task {
          await self.removeUpdateStreamContinuation(with: uuid)
        }
      }
    }
  }
  
  func removeUpdateStreamContinuation(with uuid: UUID) {
    self.continuations.removeValue(forKey: uuid)
  }
}
