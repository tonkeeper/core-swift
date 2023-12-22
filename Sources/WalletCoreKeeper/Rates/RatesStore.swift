import Foundation
import WalletCoreCore

final class RatesStore {
    typealias Stream = AsyncStream<Result<Rates, Swift.Error>>
    
    private var continuations = [UUID: Stream.Continuation]()
    
    private let ratesService: RatesService
    private let walletProvider: WalletProvider
    
    init(ratesService: RatesService,
         walletProvider: WalletProvider) {
        self.ratesService = ratesService
        self.walletProvider = walletProvider
    }
    
    var rates: Rates {
        ratesService.getRates()
    }
    
    func reloadRates(tokens: [TokenInfo]) {
        Task {
            do {
                let rates = try await ratesService.loadRates(
                    tonInfo: TonInfo(),
                    tokens: tokens,
                    currencies: Currency.allCases
                )
                continuations.values.forEach { $0.yield(.success(rates)) }
            } catch {
                continuations.values.forEach { $0.yield(.failure(error)) }
            }
        }
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
                self.removeUpdateStreamContinuation(with: uuid)
            }
        }
    }
    
    func removeUpdateStreamContinuation(with uuid: UUID) {
        self.continuations.removeValue(forKey: uuid)
    }
}
