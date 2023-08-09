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
    init(nftItem: NFTItem) throws {
        let address = try Address.parse(nftItem.address)
        var name: String?
        var imageURL: URL?
        var description: String?
        var collection: Collection?
        if case let .string(string) = nftItem.metadata["name"] {
            name = string
        }
        if case let .string(string) = nftItem.metadata["image"] {
            imageURL = URL(string: string)
        }
        if case let .string(string) = nftItem.metadata["description"] {
            description = string
        }
        if let nftCollection = nftItem.collection,
           let address = try? Address.parse(nftCollection.address) {
            collection = Collection(address: address, name: nftCollection.name)
        }
        
        if imageURL == nil,
           let previewURLString = nftItem.previews?[2].url,
           let previewURL = URL(string: previewURLString) {
            imageURL = previewURL
        }
        
        self.address = address
        self.name = name
        self.imageURL = imageURL
        self.description = description
        self.collection = collection
    }
}
