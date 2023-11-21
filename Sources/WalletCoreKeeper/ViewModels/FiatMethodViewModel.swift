//
//  FiatMethodViewModel.swift
//
//
//  Created by Grigory on 14.10.23..
//

import Foundation

public struct FiatMethodViewModel {
    public struct Button {
        public let title: String
        public let url: String?
    }
    
    public let id: String
    public let title: String
    public let description: String?
    public let token: String?
    public let iconURL: URL?
    public let actionButton: Button?
    public let infoButtons: [Button]
}
