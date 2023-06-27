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
    func load() throws -> T
}
