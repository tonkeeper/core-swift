//
//  CollectibleDetailsController.swift
//  
//
//  Created by Grigory on 22.8.23..
//

import Foundation
import TonSwift
import WalletCoreCore

public protocol CollectibleDetailsControllerDelegate: AnyObject {
    func collectibleDetailsController(_ collectibleDetailsController: CollectibleDetailsController,
                                      didUpdate model: CollectibleDetailsViewModel)
}

public final class CollectibleDetailsController {
    
    public weak var delegate: CollectibleDetailsControllerDelegate?
    
    public let collectibleAddress: Address
    private let walletProvider: WalletProvider
    private let contractBuilder: WalletContractBuilder
    private let collectiblesService: CollectiblesService
    private let dnsService: DNSService
    private let collectibleDetailsMapper: CollectibleDetailsMapper
    
    init(collectibleAddress: Address,
         walletProvider: WalletProvider,
         contractBuilder: WalletContractBuilder,
         collectiblesService: CollectiblesService,
         dnsService: DNSService,
         collectibleDetailsMapper: CollectibleDetailsMapper) {
        self.collectibleAddress = collectibleAddress
        self.walletProvider = walletProvider
        self.contractBuilder = contractBuilder
        self.collectiblesService = collectiblesService
        self.dnsService = dnsService
        self.collectibleDetailsMapper = collectibleDetailsMapper
    }
    
    public func prepareCollectibleDetails() throws {
        let collectible = try collectiblesService.getCollectible(address: collectibleAddress)
        let viewModel = buildInitialViewModel(collectible: collectible)
        delegate?.collectibleDetailsController(self, didUpdate: viewModel)
        guard collectible.dns != nil else { return }
        Task {
            async let linkedAddressTask = getDNSLinkedAddress(collectible: collectible)
            async let expirationDateTask = getDNSExpirationDate(collectible: collectible)
            
            let linkedAddress = try? await linkedAddressTask
            let expirationDate = try? await expirationDateTask
            
            let viewModel = buildDNSInfoLoadedViewModel(
                collectible: collectible,
                linkedAddress: linkedAddress,
                expirationDate: expirationDate)
            
            await MainActor.run {
                delegate?.collectibleDetailsController(self, didUpdate: viewModel)
            }
        }
    }
}

private extension CollectibleDetailsController {
    func buildInitialViewModel(collectible: Collectible) -> CollectibleDetailsViewModel {
        return collectibleDetailsMapper.map(
            collectible: collectible,
            isOwner: isOwner(collectible),
            linkedAddress: nil,
            expirationDate: nil,
            isInitial: true)
    }
    
    func buildDNSInfoLoadedViewModel(collectible: Collectible,
                                     linkedAddress: Address?,
                                     expirationDate: Date?) -> CollectibleDetailsViewModel {
        return collectibleDetailsMapper.map(
            collectible: collectible,
            isOwner: isOwner(collectible),
            linkedAddress: linkedAddress,
            expirationDate: expirationDate,
            isInitial: false)
    }
    
    func isOwner(_ collectible: Collectible) -> Bool {
        guard let wallet = try? walletProvider.activeWallet,
              let walletPublicKey = try? wallet.publicKey,
              let contract = try? contractBuilder.walletContract(with: walletPublicKey, contractVersion: wallet.contractVersion),
              let contractAddress = try? contract.address() else {
            return false
        }
        return collectible.owner?.address == contractAddress
    }

    func getDNSLinkedAddress(collectible: Collectible) async throws -> Address? {
        guard let dns = collectible.dns else { return nil }
        let linkedAddress = try await dnsService.resolveDomainName(dns).address.address
        return linkedAddress
    }
    
    func getDNSExpirationDate(collectible: Collectible) async throws -> Date? {
        guard let dns = collectible.dns else { return nil }
        let date = try await dnsService.loadDomainExpirationDate(dns)
        return date
    }
}
