//
//  TonConnectEventSuccess.swift
//  
//
//  Created by Grigory Serebryanyy on 26.10.2023.
//

import Foundation

struct TonConnectEventSuccess {
    struct Payload {
        let items: [TonConnectItemReplyWrapper]
        let device: DeviceInfo
    }

    let event = "connect"
    let id = Int(Date().timeIntervalSince1970)
    let payload: Payload
}

struct DeviceInfo: Encodable {
    let platform = "iphone"
    let appName = "Tonkeeper"
    let appVersion = "3.4.0"
    let maxProtocolVersion = 2
    let features = [Feature()]
    
    struct Feature: Encodable {
        let name = "SendTransaction"
        let maxMessages = 4
    }
}

extension TonConnectEventSuccess: Encodable {
    enum CodingKeys: String, CodingKey {
        case event
        case id
        case payload
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(event, forKey: .event)
        try container.encode(id, forKey: .id)
        try container.encode(payload, forKey: .payload)
    }
}

extension TonConnectEventSuccess.Payload: Encodable {
    enum CodingKeys: String, CodingKey {
        case items
        case device
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encode(device, forKey: .device)
    }
}

