//
//  Status.swift
//  
//
//  Created by Grigory on 3.8.23..
//

import Foundation

enum Status {
    case ok
    case failed
    case unknown(String)
    
    init(rawValue: String) {
        switch rawValue {
        case "ok": self = .ok
        case "failed": self = .failed
        default: self = .unknown(rawValue)
        }
    }
}
