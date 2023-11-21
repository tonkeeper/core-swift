//
//  DeeplinkAssembly.swift
//  
//
//  Created by Grigory on 4.7.23..
//

import Foundation

struct DeeplinkAssembly {
    func deeplinkParser(handlers: [DeeplinkHandler]) -> DeeplinkParser {
        DeeplinkParser(handlers: handlers)
    }
    
    var deeplinkGenerator: DeeplinkGenerator {
        DeeplinkGenerator()
    }
}
