//
//  LocalRepository.swift
//  
//
//  Created by Grigory on 27.6.23..
//

import Foundation

protocol LocalRepository<T> {
    associatedtype T: LocalStorable
    
    func save(item: T) throws
    func save(item: Codable, key: String) throws
    func load(fileName: String) throws -> T
    func load(key: T.KeyType) throws -> T
    func loadAll() throws -> [T]
    func remove(fileName: String) throws
}
