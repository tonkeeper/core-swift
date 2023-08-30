//
//  NFTSendController.swift
//
//
//  Created by Grigory on 30.8.23..
//

import Foundation
import TonSwift
import BigInt

public final class NFTSendController: SendController {
    
    private let collectible: Collectible
    
    init(collectible: Collectible) {
        self.collectible = collectible
    }
    
    public func getInitialTransactionModel() -> SendTransactionViewModel {
        return SendTransactionViewModel.nft(.init(title: "", image: .ton, recipientAddress: nil, recipientName: nil, feeTon: nil, feeFiat: nil, comment: nil, nftId: nil, nftCollectionId: nil))
    }
    
    public func loadTransactionModel() async throws -> SendTransactionViewModel {
        return SendTransactionViewModel.nft(.init(title: "", image: .ton, recipientAddress: nil, recipientName: nil, feeTon: nil, feeFiat: nil, comment: nil, nftId: nil, nftCollectionId: nil))
    }
    
    public func sendTransaction() async throws {
        
    }
    
    
}
