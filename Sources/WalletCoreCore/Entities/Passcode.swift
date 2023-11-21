//
//  Passcode.swift
//  
//
//  Created by Grigory Serebryanyy on 20.11.2023.
//

import Foundation

public struct Passcode: Codable, Equatable {
    enum Error: Swift.Error {
        case incorrentLength(Int)
    }
    
    public static let length = 4
    private let value: String
    
    public init(value: String) throws {
        guard value.count == Passcode.length else {
            throw Error.incorrentLength(value.count)
        }
        self.value = value
    }
}
