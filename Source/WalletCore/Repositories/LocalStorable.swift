//
//  LocalStorable.swift
//  
//
//  Created by Grigory on 27.6.23..
//

import Foundation

protocol LocalStorable: Codable {
    var fileName: String { get }
    static var fileName: String { get }
}
