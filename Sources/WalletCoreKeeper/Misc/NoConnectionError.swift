//
//  NoConnectionError.swift
//  
//
//  Created by Grigory Serebryanyy on 25.10.2023.
//

import Foundation

public extension Swift.Error {
    var isNoConnectionError: Bool {
        guard (self as NSError).domain == URLError.errorDomain else { return false }
        switch (self as NSError).code {
        case URLError.Code.notConnectedToInternet.rawValue,
            URLError.Code.networkConnectionLost.rawValue:
            return true
        default:
            return false
        }
    }
}
