import Foundation
import TonSwift
import WalletCoreCore

protocol BalanceService {
    func loadBalance(address: Address) async throws -> WalletBalanceState
    func getCachedBalance(address: Address) throws -> WalletBalanceState
}

final class BalanceServiceImplementation: BalanceService {
    private let tonBalanceService: AccountTonBalanceService
    private let tokensBalanceService: AccountTokensBalanceService
    private let collectiblesService: CollectiblesService
    private let localRepository: any LocalRepository<WalletBalanceState>
    
    init(tonBalanceService: AccountTonBalanceService,
         tokensBalanceService: AccountTokensBalanceService,
         collectiblesService: CollectiblesService,
         localRepository: any LocalRepository<WalletBalanceState>) {
        self.tonBalanceService = tonBalanceService
        self.tokensBalanceService = tokensBalanceService
        self.collectiblesService = collectiblesService
        self.localRepository = localRepository
    }
    
    func loadBalance(address: Address) async throws -> WalletBalanceState {
        async let tonBalanceTask = loadTonBalance(address: address)
        async let tokensTask = loadTokensBalance(address: address)
        async let collectiblesBalancesTask = loadCollectiblesBalance(address: address)
        
        let tonBalance = try await tonBalanceTask
        let tokensBalance = try await tokensTask
        let collectiblesBalance = try await collectiblesBalancesTask
        
        let walletBalance = WalletBalance(
            walletAddress: address,
            tonBalance: tonBalance,
            tokensBalance: tokensBalance,
            previousRevisionsBalances: [],
            collectibles: collectiblesBalance
        )
        
        let balanceState = WalletBalanceState(date: Date(),
                                        balance: walletBalance)
        
        try? localRepository.save(item: balanceState)
        
        return balanceState
    }
    
    func getCachedBalance(address: Address) throws -> WalletBalanceState {
        return try localRepository.load(fileName: address.toRaw())
    }
}

private extension BalanceServiceImplementation {
    func loadTonBalance(address: Address) async throws -> TonBalance {
        return try await tonBalanceService.loadBalance(address: address)
    }
    
    func loadTokensBalance(address: Address) async throws -> [TokenBalance] {
        return try await tokensBalanceService.loadTokensBalance(address: address)
    }
    
    func loadCollectiblesBalance(address: Address) async throws -> [Collectible] {
        return try await collectiblesService.loadCollectibles(address: address,
                                                              collectionAddress: nil,
                                                              limit: 1000, offset: 0,
                                                              isIndirectOwnership: true)
    }
}
