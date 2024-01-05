//
//  DeeplinkParser.swift
//  
//
//  Created by Grigory on 4.7.23..
//

import Foundation
import TonSwift

public protocol DeeplinkHandler {
    func parse(string: String) throws -> Deeplink
    func isValid(deeplink: Deeplink) -> Bool
}

struct TonDeeplinkHandler: DeeplinkHandler {
    func isValid(deeplink: Deeplink) -> Bool {
        guard case .ton = deeplink else {
            return false
        }
        return true
    }
    
    func parse(string: String) throws -> Deeplink {
        guard let url = URL(string: string),
              let scheme = url.scheme,
              let host = url.host,
              !url.lastPathComponent.isEmpty
        else { throw DeeplinkParser.Error.failedToParse(string: string) }
        switch scheme {
        case "ton":
            switch host {
            case "transfer":
                let addressString = url.lastPathComponent
                let recipientAddress = try Recipient.RecipientAddress(string: addressString)
                return .ton(.transfer(recipient: Recipient(address: recipientAddress, domain: nil)))
            default:
                throw DeeplinkParser.Error.failedToParse(string: string)
            }
        default: throw DeeplinkParser.Error.failedToParse(string: string)
        }
    }
}

struct TonConnectDeeplinkHandler: DeeplinkHandler {
    func isValid(deeplink: Deeplink) -> Bool {
        guard case .tonConnect = deeplink else {
            return false
        }
        return true
    }
    
    func parse(string: String) throws -> Deeplink {
        if let deeplink = try? parseTonConnectDeeplink(string: string) {
            return deeplink
        }
        if let universalLink = try? parseTonConnectUniversalLink(string: string) {
            return universalLink
        }
        throw DeeplinkParser.Error.failedToParse(string: string)
    }
    
    private func parseTonConnectDeeplink(string: String) throws -> Deeplink {
        guard let url = URL(string: string),
              let scheme = url.scheme
        else { throw DeeplinkParser.Error.failedToParse(string: string) }
        switch scheme {
        case "tc":
            return .tonConnect(.init(string: string))
        default: throw DeeplinkParser.Error.failedToParse(string: string)
        }
    }
    
    private func parseTonConnectUniversalLink(string: String) throws -> Deeplink {
        guard let url = URL(string: string),
              let components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: true
              ) else { throw DeeplinkParser.Error.failedToParse(string: string) }
        switch url.path {
        case "/ton-connect":
            var tcComponents = URLComponents()
            tcComponents.scheme = "tc"
            tcComponents.queryItems = components.queryItems
            guard let string = tcComponents.string else { throw DeeplinkParser.Error.failedToParse(string: string) }
            return .tonConnect(.init(string: string))
        default:
            throw DeeplinkParser.Error.failedToParse(string: string)
        }
    }
}

public struct DeeplinkParser {
    
    private let handlers: [DeeplinkHandler]
    
    init(handlers: [DeeplinkHandler]) {
        self.handlers = handlers
    }

    enum Error: Swift.Error {
        case failedToParse(string: String)
    }
    
    public func isValid(string: String) throws -> Bool {
        let deeplink = try parse(string: string)
        return handlers
            .map { handler -> Bool in handler.isValid(deeplink: deeplink) }
            .reduce(into: false) { $0 = $0 || $1 }
    }
    
    public func parse(string: String) throws -> Deeplink {
        let deeplink = handlers
            .compactMap { handler -> Deeplink? in try? handler.parse(string: string) }
            .first
        guard let deeplink = deeplink else { throw Error.failedToParse(string: string) }
        return deeplink
    }
}
