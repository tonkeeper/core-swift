//
//  CollectibleDetailsMapper.swift
//  
//
//  Created by Grigory on 24.8.23..
//

import Foundation

struct CollectibleDetailsMapper {
    func map(collectible: Collectible, isOwner: Bool) -> CollectibleDetailsViewModel {
        return CollectibleDetailsViewModel(
            title: collectible.name,
            collectibleDetails: mapCollectibleDetails(collectible: collectible),
            collectionDetails: mapCollectionDetails(collectible: collectible),
            properties: mapProperties(collectible: collectible),
            details: mapDetails(collectible: collectible),
            isTransferEnable: mapIsTransferEnable(collectible: collectible, isOwner: isOwner),
            isOnSale: collectible.sale != nil)
    }
    
    private func mapCollectibleDetails(collectible: Collectible) -> CollectibleDetailsViewModel.CollectibleDetails {
        var subtitle: String?
        if collectible.dns != nil {
            subtitle = "TON DNS"
        } else if let collection = collectible.collection, let collectionName = collection.name {
            subtitle = collectionName
        }
        
        let imageURL = collectible.preview.size1500 ?? collectible.preview.size500 ?? collectible.imageURL
        
        return CollectibleDetailsViewModel.CollectibleDetails(
            imageURL: imageURL,
            title: collectible.name,
            subtitle: subtitle,
            description: collectible.description
        )
    }
    
    private func mapCollectionDetails(collectible: Collectible) -> CollectibleDetailsViewModel.CollectionDetails {
        var title: String?
        var description: String?
        if collectible.dns != nil {
            title = "About TON DNS"
            description = .tonDNSDescription
        } else if let collectionName = collectible.collection?.name {
            title = "About \(collectionName)"
            description = collectible.collection?.description
        }
        
        return CollectibleDetailsViewModel.CollectionDetails(
            title: title,
            description: description
        )
    }
    
    private func mapProperties(collectible: Collectible) -> [CollectibleDetailsViewModel.Property] {
        collectible.attributes.map { CollectibleDetailsViewModel.Property(title: $0.key, value: $0.value) }
    }
    
    private func mapDetails(collectible: Collectible) -> CollectibleDetailsViewModel.Details {
        var items = [CollectibleDetailsViewModel.Details.Item]()
        if let owner = collectible.owner {
            items.append(.init(title: "Owner", value: owner.address.shortString))
        }
        items.append(.init(title: "Contract address", value: collectible.address.shortString))
        
        let url = URL.tonviewerURL.appendingPathComponent(collectible.address.toString())
        return CollectibleDetailsViewModel.Details(items: items, url: url)
    }
    
    private func mapIsTransferEnable(
        collectible: Collectible,
        isOwner: Bool) -> Bool {
            return collectible.sale == nil && isOwner
    }
}

private extension URL {
    static let tonviewerURL = URL(string: "https://tonviewer.com/")!
}

private extension String {
    static let tonDNSDescription = """
    TON DNS is a service that allows users to assign a human-readable name to crypto wallets, smart contracts, and websites.\n\nWith TON DNS, access to decentralized services is analogous to access to websites on the internet.
    """
}
