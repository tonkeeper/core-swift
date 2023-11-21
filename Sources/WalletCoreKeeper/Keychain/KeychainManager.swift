//
//  KeychainManager.swift
//  
//
//  Created by Grigory on 22.6.23..
//

import Foundation

final class KeychainManager {
    enum Error: Swift.Error, Equatable {
        case noItemFound
        case error(KeychainResultCode)
        case invalidData
    }
    
    private let keychain: Keychain
    
    init(keychain: Keychain) {
        self.keychain = keychain
    }
    
    func get(query: KeychainQuery) throws -> Data {
        let result = keychain.get(query: query)
        switch result {
        case let .success(data):
            guard let data = data else {
                throw Error.invalidData
            }
            return data
        case let .failed(resultCode):
            switch resultCode {
            case .errSecItemNotFound:
                throw Error.noItemFound
            default:
                throw Error.error(resultCode)
            }
        }
    }
    
    func save(data: Data, query: KeychainQuery) throws {
        do {
            _ = try get(query: query)
            var query = query
            query.returnData = false
            
            let updateResult = keychain.update(query: query,
                                               attributes: [KeychainKeys.valueData: data as AnyObject])
            
            guard case .success = updateResult else {
                throw Error.error(updateResult)
            }
        } catch Error.noItemFound {
            var query = query
            query.data = data
            let saveResult = keychain.save(query: query)
            guard case .success = saveResult else {
                throw Error.error(saveResult)
            }
        }
    }
    
    func delete(query: KeychainQuery) throws {
        let deleteResult = keychain.delete(query: query)
        if deleteResult != .success && deleteResult != .errSecItemNotFound {
            throw Error.error(deleteResult)
        }
    }
    
    func deleteAll(group: String?) throws {
        let deleteResult = keychain.deleteAll(group: group)
        if deleteResult != .success && deleteResult != .errSecItemNotFound {
            throw Error.error(deleteResult)
        }
    }
}
