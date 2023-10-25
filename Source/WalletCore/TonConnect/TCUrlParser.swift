//
//  TCUrlParser.swift
//  
//
//  Created by Grigory Serebryanyy on 18.10.2023.
//

import Foundation

struct TCUrlParser {
    enum Error: Swift.Error {
        case incorrectUrl
    }
    
    func parseString(_ string: String) throws -> TCParameters {
        guard
            let url = URL(string: string),
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            components.scheme == .tcScheme,
            let queryItems = components.queryItems,
            let versionValue = queryItems.first(where: { $0.name == .versionKey })?.value,
            let version = TCParameters.Version(rawValue: versionValue),
            let clientId = queryItems.first(where: { $0.name == .clientIdKey })?.value,
            let requestPayloadValue = queryItems.first(where: { $0.name == .requestPayloadKey })?.value,
            let requestPayloadData = requestPayloadValue.data(using: .utf8),
            let requestPayload = try? JSONDecoder().decode(TCRequestPayload.self, from: requestPayloadData)
        else {
            throw Error.incorrectUrl
        }
        
        return TCParameters(
            version: version,
            clientId: clientId,
            requestPayload: requestPayload)
    }
}

private extension String {
    static let tcScheme = "tc"
    static let versionKey = "v"
    static let clientIdKey = "id"
    static let requestPayloadKey = "r"
}
