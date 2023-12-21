import Foundation
import WalletCoreCore

final class BalanceStore {
    typealias Stream = AsyncStream<Result<WalletBalanceState, Swift.Error>>

    private var continuations = [UUID: Stream.Continuation]()
    
    private let balanceService: BalanceService
    private let walletProvider: WalletProvider
    
    init(balanceService: BalanceService,
         walletProvider: WalletProvider) {
        self.balanceService = balanceService
        self.walletProvider = walletProvider
    }
    
    var balanceState: WalletBalanceState {
        get throws {
            try getBalanceState()
        }
    }
    
    func reloadBalance() {
        reloadBalanceState()
    }
    
    func updateStream() -> Stream {
        createUpdateStream()
    }
}

private extension BalanceStore {
    func reloadBalanceState() {
        Task {
            do {
                let balanceState = try await balanceService.loadBalance(address: try walletProvider.activeWallet.address)
                continuations.values.forEach { $0.yield(.success(balanceState)) }
            } catch {
                continuations.values.forEach { $0.yield(.failure(error)) }
            }
        }
    }
    
    func getBalanceState() throws -> WalletBalanceState {
        try balanceService.getCachedBalance(address: try walletProvider.activeWallet.address)
    }
    
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
