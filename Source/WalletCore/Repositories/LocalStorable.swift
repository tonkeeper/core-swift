//
//  LocalStorable.swift
//  
//
//  Created by Grigory on 27.6.23..
//

import Foundation

protocol LocalStorable: Codable {
    static var fileName: String { get }
}
