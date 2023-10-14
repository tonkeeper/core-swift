//
//  FiatMethods.swift
//
//
//  Created by Grigory on 14.10.23..
//

import Foundation

struct FiatMethodItem: Codable {
    typealias ID = String
    
    struct ActionButton: Codable {
        let title: String
        let url: String
        
        enum CodingKeys: String, CodingKey {
            case title
            case url
        }
    }
    
    let id: ID
    let title: String
    let isDisabled: Bool?
    let badge: String?
    let subtitle: String?
    let description: String?
    let iconURL: URL?
    let actionButton: ActionButton
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case isDisabled = "disabled"
        case badge
        case subtitle
        case description
        case iconURL = "icon_url"
        case actionButton = "action_button"
    }
}

struct FiatMethodCategory: Codable {
    enum CategoryType: String, Codable {
        case buy
        case sell
    }
    
    let type: CategoryType
    let title: String?
    let subtitle: String?
    let items: [FiatMethodItem]
}

struct FiatMethodLayout: Codable {
    let countryCode: String?
    let currency: String?
    let methods: [FiatMethodItem.ID]
}

struct FiatMethods: Codable, LocalStorable {
    typealias KeyType = String
    
    var key: String {
        fileName
    }
    
    let layoutByCountry: [FiatMethodLayout]
    let defaultLayout: FiatMethodLayout
    let categories: [FiatMethodCategory]
}

struct FiatMethodsResponse: Codable {
    let data: FiatMethods
}
