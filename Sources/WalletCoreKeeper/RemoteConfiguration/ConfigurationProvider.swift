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

protocol CacheConfigurationProvider: ConfigurationProvider {
    func saveConfiguration(_ configuration: RemoteConfiguration) throws
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
                subdirectory: "PackageResources"
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

final class DefaultCacheConfigurationProvider: CacheConfigurationProvider {
    var configuration: RemoteConfiguration {
        get throws {
            let data = try Data(contentsOf: filePath)
            let jsonDecoder = JSONDecoder()
            return try jsonDecoder.decode(RemoteConfiguration.self, from: data)
        }
    }
    
    private let cachePath: URL
    private let fileManager: FileManager
    
    private var filePath: URL {
        if #available(iOS 16.0, macOS 13.0, *) {
            return cachePath.appending(path: String.cachedConfigurationFileName)
        } else {
            return cachePath.appendingPathComponent(String.cachedConfigurationFileName)
        }
    }
    
    init(cachePath: URL,
         fileManager: FileManager) {
        self.cachePath = cachePath
        self.fileManager = fileManager
    }
    
    func saveConfiguration(_ configuration: RemoteConfiguration) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(configuration)
        if !fileManager.fileExists(atPath: cachePath.path) {
            try fileManager.createDirectory(atPath: cachePath.path, withIntermediateDirectories: true)
        }
        
        if fileManager.fileExists(atPath: filePath.path) {
            try fileManager.removeItem(at: filePath)
        }
        fileManager.createFile(atPath: filePath.path, contents: data)
    }
}

private extension String {
    static let defaultConfigurationFileName = "DefaultConfiguration.json"
    static let cachedConfigurationFileName = "CachedConfiguration.json"
}
