//
//  LocalDiskRepository.swift
//  
//
//  Created by Grigory on 27.6.23..
//

import Foundation

struct LocalDiskRepository<T: Codable & LocalStorable>: LocalRepository {
    private let fileManager: FileManager
    private let directory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init(fileManager: FileManager,
         directory: URL,
         encoder: JSONEncoder,
         decoder: JSONDecoder) {
        self.fileManager = fileManager
        self.directory = directory
        self.encoder = encoder
        self.decoder = decoder
    }
    
    func save(item: T) throws {
        let path = itemPath(itemType: type(of: item))
        try createFolderIfNeeded(url: path)
        if fileManager.fileExists(atPath: path.path) {
            try fileManager.removeItem(at: path)
        }
        
        let data = try encoder.encode(item)
        try data.write(to: path, options: .atomic)
    }
    
    func load() throws -> T {
        let path = itemPath(itemType: T.self)
        let data = try Data(contentsOf: path)
        let item = try decoder.decode(T.self, from: data)
        return item
    }
}

private extension LocalDiskRepository {
    func folderPath() -> URL {
        let typeFolder = String(describing: T.self)
        let folderURL = directory.appendingPathComponent(typeFolder, isDirectory: true)
        return folderURL
    }
    
    func itemPath(itemType: T.Type) -> URL {
        return folderPath().appendingPathComponent(itemType.fileName)
    }
    
    func createFolderIfNeeded(url: URL) throws {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
