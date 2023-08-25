//
//  File.swift
//  
//
//  Created by Grigory on 4.8.23..
//

import Foundation
import TonAPI
import TonSwift

extension Collectible {
    private enum PreviewSize: String {
        case size5 = "5x5"
        case size100 = "100x100"
        case size500 = "500x500"
        case size1500 = "1500x1500"
    }
    
    init(nftItem: NFTItem) throws {
        let address = try Address.parse(nftItem.address)
        var owner: WalletAccount?
        var name: String?
        var imageURL: URL?
        var description: String?
        var collection: Collection?
        
        if let ownerAccountAddress = nftItem.owner, let ownerWalletAccount = try? WalletAccount(accountAddress: ownerAccountAddress) {
            owner = ownerWalletAccount
        }
        
        if case let .string(string) = nftItem.metadata["name"] {
            name = string
        }
        if case let .string(string) = nftItem.metadata["image"] {
            imageURL = URL(string: string)
        }
        if case let .string(string) = nftItem.metadata["description"] {
            description = string
        }
        
        var attributes = [Attribute]()
        if case let .array(nftAttributes) = nftItem.metadata["attributes"] {
            attributes = nftAttributes
                .compactMap { json -> [String: AnyJSON]? in
                    guard case let .object(attribute) = json else { return nil }
                    return attribute
                }
                .compactMap { attributeObject -> Attribute? in
                    guard case let .string(key) = attributeObject["trait_type"] else { return nil}
                    let value: String
                    switch attributeObject["value"] {
                    case .string(let stringValue):
                        value = stringValue
                    case .number(let numberValue):
                        value = String(numberValue)
                    default:
                        value = "-"
                    }
                    return Attribute(key: key, value: value)
                }
        }

        if let nftCollection = nftItem.collection,
           let address = try? Address.parse(nftCollection.address) {
            collection = Collection(address: address, name: nftCollection.name, description: nftCollection.description)
        }
        
        if imageURL == nil,
           let previewURLString = nftItem.previews?[2].url,
           let previewURL = URL(string: previewURLString) {
            imageURL = previewURL
        }
        
        var sale: Sale?
        if let nftSale = nftItem.sale {
            let address = try Address.parse(nftSale.address)
            let market = try WalletAccount(accountAddress: nftSale.market)
            var ownerWalletAccount: WalletAccount?
            if let nftSaleOwner = nftItem.owner {
                ownerWalletAccount = try WalletAccount(accountAddress: nftSaleOwner)
            }
            sale = Sale(address: address, market: market, owner: ownerWalletAccount)
        }
        
        self.address = address
        self.owner = owner
        self.name = name
        self.imageURL = imageURL
        self.description = description
        self.attributes = attributes
        self.preview = Self.mapPreviews(nftItem.previews)
        self.collection = collection
        self.dns = nftItem.dns
        self.sale = sale
    }
    
    static private func mapPreviews(_ previews: [ImagePreview]?) -> Preview {
        var size5: URL?
        var size100: URL?
        var size500: URL?
        var size1500: URL?
        
        previews?.forEach { preview in
            guard let previewSize = PreviewSize(rawValue: preview.resolution) else { return }
            switch previewSize {
            case .size5:
                size5 = URL(string: preview.url)
            case .size100:
                size100 = URL(string: preview.url)
            case .size500:
                size500 = URL(string: preview.url)
            case .size1500:
                size1500 = URL(string: preview.url)
            }
        }
        return Preview(size5: size5, size100: size100, size500: size500, size1500: size1500)
    }
}
