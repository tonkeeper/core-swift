//
//  LocalStorable.swift
//  
//
//  Created by Grigory on 27.6.23..
//

import Foundation

protocol LocalStorable: Codable {
    associatedtype KeyType: CustomStringConvertible
    
    var key: KeyType { get }
    
    var fileName: String { get }
    static var fileName: String { get }
}

extension LocalStorable {
    static var fileName: String {
        String(describing: self)
    }
    var fileName: String {
        String(describing: type(of: self))
    }
}
