//
//  RemoteConfigurationProvider.swift
//  
//
//  Created by Grigory on 20.6.23..
//

import Foundation

protocol ConfigurationProvider {
    var configuration: RemoteConfiguration { get throws }
}

final class DefaultConfigurationProvider: ConfigurationProvider {
    enum Error: Swift.Error {
        case noDefaultConfigurationInBundle
        case defaultConfigurationCorrupted
    }
    
    var configuration: RemoteConfiguration {
        get throws {
            guard let configurationURL = bundle.url(
                forResource: defaultConfigurationFileName,
                withExtension: nil,
                subdirectory: "Resources"
            ) else {
                throw Error.noDefaultConfigurationInBundle
            }
            let decoder = JSONDecoder()
            do {
                let configurationData = try Data(contentsOf: configurationURL)
                let configuration = try decoder.decode(RemoteConfiguration.self, from: configurationData)
                return configuration
            } catch {
                throw Error.defaultConfigurationCorrupted
            }
        }
    }
    
    private let defaultConfigurationFileName: String
    private let bundle: Bundle
    
    init(defaultConfigurationFileName: String = .defaultConfigurationFileName, bundle: Bundle = .module) {
        self.defaultConfigurationFileName = defaultConfigurationFileName
        self.bundle = bundle
    }
}


private extension String {
    static let defaultConfigurationFileName = "DefaultConfiguration.json"
}
