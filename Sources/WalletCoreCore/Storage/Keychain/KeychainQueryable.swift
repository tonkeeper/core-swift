//
//  KeychainQueryable.swift
//
//
//  Created by Grigory Serebryanyy on 20.11.2023.
//

import Foundation

public protocol KeychainQueryable {
    var query: [String: AnyObject] { get throws }
}
