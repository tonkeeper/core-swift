//
//  FileSystemVault.swift
//
//
//  Created by Grigory Serebryanyy on 18.11.2023.
//

import Foundation

struct FileSystemVault<T: KeyValueVaultValue>: StorableVault {
    enum Error: Swift.Error {
        case noItem(key: T.Key)
        case corruptedData(key: T.Key, error: DecodingError)
    }
    
    private let fileManager: FileManager
    private let directory: URL
    
    init(fileManager: FileManager,
         directory: URL) {
        self.fileManager = fileManager
        self.directory = directory
        
    }
    
    func loadValue(key: T.Key) throws -> T {
        do {
            return try loadValue(filename: key.description)
        } catch CocoaError.fileReadNoSuchFile {
            throw Error.noItem(key: key)
        } catch let decodingError as DecodingError {
            throw Error.corruptedData(key: key, error: decodingError)
        } catch {
            throw error
        }
    }
    
    func loadAllValues() throws -> [T] {
        (try? fileManager.contentsOfDirectory(atPath: folderPath.path))?
            .compactMap { name -> T? in
                return try? loadValue(filename: name)
            } ?? []
    }
    
    func saveValue(_ value: T, for key: T.Key) throws {
        let url = buildUrl(filename: key.description)
        try createFolderIfNeeded(url: url)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomic)
    }
    
    func deleteValue(for key: T.Key) throws {
        try deleteValue(filename: key.description)
    }
    
    func deleteAllValues() throws {
        try fileManager.contentsOfDirectory(atPath: folderPath.path)
            .forEach { try deleteValue(filename: $0) }
    }
}

private extension FileSystemVault {
    var folderPath: URL {
        let folderName = String(describing: T.self)
        let folderPath: URL
        if #available(iOS 16.0, macOS 13.0, *) {
            folderPath = directory.appending(path: folderName)
        } else {
            folderPath = directory.appendingPathComponent(
                folderName,
                isDirectory: true
            )
        }
        return folderPath
    }
    
    func createFolderIfNeeded(url: URL) throws {
        let path: String
        if #available(iOS 16.0, macOS 13.0, *) {
            path = url.path()
        } else {
            path = url.path
        }
        guard fileManager.fileExists(atPath: path) else { return }
        try fileManager.createDirectory(
            atPath: path,
            withIntermediateDirectories: true
        )
    }
    
    func buildUrl(filename: String) -> URL {
        let url: URL
        if #available(iOS 16.0, macOS 13.0, *) {
            url = folderPath.appending(path: filename)
        } else {
            url = folderPath.appendingPathComponent(filename)
        }
        return url
    }
    
    func loadValue(filename: String) throws -> T {
        let url = buildUrl(filename: filename)
        let data = try Data(contentsOf: url)
        let item = try JSONDecoder().decode(T.self, from: data)
        return item
    }
    
    func deleteValue(filename: String) throws {
        let url = buildUrl(filename: filename)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
}
