//
//  DeeplinkParser.swift
//  
//
//  Created by Grigory on 4.7.23..
//

import Foundation
import TonSwift

public struct DeeplinkParser {
    
    enum Error: Swift.Error {
        case failedToParse(string: String)
    }
    
    public func parse(string: String) throws -> Deeplink {
        guard let url = URL(string: string),
              let scheme = url.scheme,
              let host = url.host,
              !url.lastPathComponent.isEmpty
        else  { throw Error.failedToParse(string: string) }
        
        
        switch scheme {
        case "ton":
            switch host {
            case "transfer":
                return .ton(.transfer(address: url.lastPathComponent))
            default:
                throw Error.failedToParse(string: string)
            }
        default: throw Error.failedToParse(string: string)
        }
    }
}
