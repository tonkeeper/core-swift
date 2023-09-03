//
//  CollectibleDetailsController.swift
//  
//
//  Created by Grigory on 22.8.23..
//

import Foundation
import TonSwift

public final class CollectibleDetailsController {
    
    public let collectibleAddress: Address
    private let walletProvider: WalletProvider
    private let contractBuilder: WalletContractBuilder
    private let collectiblesService: CollectiblesService
    private let collectibleDetailsMapper: CollectibleDetailsMapper
    
    init(collectibleAddress: Address,
         walletProvider: WalletProvider,
         contractBuilder: WalletContractBuilder,
         collectiblesService: CollectiblesService,
         collectibleDetailsMapper: CollectibleDetailsMapper) {
        self.collectibleAddress = collectibleAddress
        self.walletProvider = walletProvider
        self.contractBuilder = contractBuilder
        self.collectiblesService = collectiblesService
        self.collectibleDetailsMapper = collectibleDetailsMapper
    }
    
    public func getCollectibleModel() throws -> CollectibleDetailsViewModel {
        let collectible = try collectiblesService.getCollectible(address: collectibleAddress)
        let viewModel = collectibleDetailsMapper.map(
            collectible: collectible,
            isOwner: isOwner(collectible)
        )
        return viewModel
    }
}

private extension CollectibleDetailsController {
    func isOwner(_ collectible: Collectible) -> Bool {
        guard let wallet = try? walletProvider.activeWallet,
              let walletPublicKey = try? wallet.publicKey,
              let contract = try? contractBuilder.walletContract(with: walletPublicKey, contractVersion: wallet.contractVersion),
              let contractAddress = try? contract.address() else {
            return false
        }
        return collectible.owner?.address == contractAddress
    }
}
