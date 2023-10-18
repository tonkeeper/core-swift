//
//  TCParameters.swift
//  
//
//  Created by Grigory Serebryanyy on 18.10.2023.
//

import Foundation

struct TCParameters {
    enum Version: String {
        case v2 = "2"
    }
    
    let version: Version
    let clientId: String
    let requestPayload: TCRequestPayload
}
