//
//  MockDefaultConfigurationProvider.swift
//  
//
//  Created by Grigory on 21.6.23..
//

import Foundation
@testable import WalletCore

final class MockDefaultConfigurationProvider: ConfigurationProvider {
    var configuration: WalletCore.RemoteConfiguration {
        .empty
    }
}
