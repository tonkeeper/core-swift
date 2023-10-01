//
//  WalletBalanceService.swift
//
//
//  Created by Grigory on 1.7.23..
//

import Foundation
import TonSwift

protocol WalletBalanceService {
    func loadWalletBalance(wallet: Wallet) async throws -> WalletBalance
    func getWalletBalance(wallet: Wallet) throws -> WalletBalance
    func getEmptyWalletBalance(wallet: Wallet) throws -> WalletBalance
}

final class WalletBalanceServiceImplementation: WalletBalanceService {
    private let tonBalanceService: AccountTonBalanceService
    private let tokensBalanceService: AccountTokensBalanceService
    private let collectiblesService: CollectiblesService
    private let walletContractBuilder: WalletContractBuilder
    private let localRepository: any LocalRepository<WalletBalance>
    
    init(tonBalanceService: AccountTonBalanceService,
         tokensBalanceService: AccountTokensBalanceService,
         collectiblesService: CollectiblesService,
         walletContractBuilder: WalletContractBuilder,
         localRepository: any LocalRepository<WalletBalance>) {
        self.tonBalanceService = tonBalanceService
        self.tokensBalanceService = tokensBalanceService
        self.collectiblesService = collectiblesService
        self.walletContractBuilder = walletContractBuilder
        self.localRepository = localRepository
    }
    
    func getWalletBalance(wallet: Wallet) throws -> WalletBalance {
        let publicKey = try wallet.publicKey
        let contract = try walletContractBuilder.walletContract(
            with: publicKey,
            contractVersion: wallet.contractVersion
        )
        let address = try contract.address()
        return try localRepository.load(fileName: address.toRaw())
    }
    
    func loadWalletBalance(wallet: Wallet) async throws -> WalletBalance {
        let publicKey = try wallet.publicKey
        let contract = try walletContractBuilder.walletContract(
            with: publicKey,
            contractVersion: wallet.contractVersion
        )
        let address = try contract.address()
        
        async let tonBalanceTask = loadTonBalance(address: address)
        async let tokensTask = loadTokensBalance(address: address)
        async let previousRevisionsBalancesTask = loadPreviousRevisionsTonBalances(
            contractVersion: wallet.contractVersion,
            publicKey: publicKey
        )
        async let collectiblesBalancesTask = loadCollectiblesBalance(address: address)
        
        let tonBalance = try await tonBalanceTask
        let tokensBalance = try? await tokensTask
        let collectiblesBalance = try? await collectiblesBalancesTask
        let previousRevisionsBalances = try? await previousRevisionsBalancesTask
        
        let walletBalance = WalletBalance(
            walletAddress: address,
            tonBalance: tonBalance,
            tokensBalance: tokensBalance ?? [],
            previousRevisionsBalances: previousRevisionsBalances ?? [],
            collectibles: collectiblesBalance ?? []
        )
        
        try? localRepository.save(item: walletBalance)
        
        return walletBalance
    }
    
    func getEmptyWalletBalance(wallet: Wallet) throws -> WalletBalance {
        let publicKey = try wallet.publicKey
        let contract = try walletContractBuilder.walletContract(
            with: publicKey,
            contractVersion: wallet.contractVersion
        )
        let address = try contract.address()
        
        return WalletBalance(walletAddress: address,
                             tonBalance: .init(walletAddress: address, amount: .init(quantity: 0)),
                             tokensBalance: [],
                             previousRevisionsBalances: [],
                             collectibles: [])
    }
}

private extension WalletBalanceServiceImplementation {
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
    
    func loadPreviousRevisionsTonBalances(contractVersion: WalletContractVersion,
                                          publicKey: TonSwift.PublicKey) async throws -> [TonBalance] {
        let addresses = previousRevisionsAddresses(contractVersion: contractVersion,
                                                   publicKey: publicKey)
        
        return try await loadTonBalances(addresses: addresses)
    }
    
    func previousRevisionsAddresses(contractVersion: WalletContractVersion,
                                    publicKey: TonSwift.PublicKey) -> [Address] {
        return contractVersion.previousContractVersions.compactMap {
            guard let contract = try? walletContractBuilder.walletContract(
                with: publicKey,
                contractVersion: $0),
                  let address = try? contract.address()
            else {
                return nil
            }
            return address
        }
    }
    
    func loadTonBalances(addresses: [Address]) async throws -> [TonBalance] {
        return try await withThrowingTaskGroup(of: TonBalance.self) { [weak self] group in
            guard let self = self else { return [] }
            for address in addresses {
                group.addTask {
                    let balance = try await self.tonBalanceService.loadBalance(address: address)
                    return balance
                }
            }
            
            var balances = [TonBalance]()
            for try await balance in group {
                balances.append(balance)
            }
            
            return balances
        }
    }
}

private extension WalletContractVersion {
    var previousContractVersions: [WalletContractVersion] {
        switch self {
        case .v4R2:
            return [.v4R1, .v3R2, .v3R1]
        case .v4R1:
            return [.v3R2, .v3R1]
        case .v3R2:
            return [.v3R1]
        case .v3R1:
            return []
        case .NA:
            return []
        }
    }
}

extension Wallet {
    enum Error: Swift.Error {
        case notAvailableWalletKind
    }
    var publicKey: TonSwift.PublicKey {
        get throws {
            switch identity.kind {
            case let .Regular(publicKey):
                return publicKey
            default:
                throw Error.notAvailableWalletKind
            }
        }
    }
}
