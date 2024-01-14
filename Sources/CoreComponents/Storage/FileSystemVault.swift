import Foundation

struct FileSystemVault<T: Codable, Key: CustomStringConvertible> {
  enum LoadError: Swift.Error {
    case noItem(key: Key)
    case corruptedData(key: Key, error: DecodingError)
    case other(Swift.Error)
  }
  
  enum SaveError: Swift.Error {
    case failedCreateFolder(url: URL)
    case corruptedData(key: Key, error: EncodingError)
    case failedSaveItem(key: Key, error: Swift.Error)
  }
  
  enum DeleteError: Swift.Error {
    case noItem(key: Key)
    case failedDeleteItem(key: Key, error: Swift.Error)
  }
  
  private let fileManager: FileManager
  private let directory: URL
  
  private let decoder = JSONDecoder()
  
  init(fileManager: FileManager,
       directory: URL) {
    self.fileManager = fileManager
    self.directory = directory
  }
  
  func loadItem(key: Key) -> Result<T, LoadError> {
    do {
      return .success(try load(filename: key.description))
    } catch CocoaError.fileReadNoSuchFile {
      return .failure(.noItem(key: key))
    } catch let decodingError as DecodingError {
      return .failure(.corruptedData(key: key, error: decodingError))
    } catch {
      return .failure(.other(error))
    }
  }
  
  func loadAll() -> [T] {
    do {
      let content = try fileManager.contentsOfDirectory(atPath: folderPath.path)
      return content.compactMap { name -> T? in
        try? load(filename: name)
      }
    } catch {
      return []
    }
  }
  
  func saveItem(_ item: T, key: Key) -> Result<Void, SaveError> {
    do {
      try createFolderIfNeeded(url: folderPath)
    } catch {
      return .failure(.failedCreateFolder(url: folderPath))
    }
    let url = folderPath.appendingPathComponent(key.description)
    do {
      if fileManager.fileExists(atPath: url.path) {
          try fileManager.removeItem(at: url)
      }
    } catch {
      return .failure(.failedSaveItem(key: key, error: error))
    }
    do {
      let data = try JSONEncoder().encode(item)
      try data.write(to: url, options: .atomic)
      return .success(())
    } catch let encodingError as EncodingError {
      return .failure(.corruptedData(key: key, error: encodingError))
    } catch {
      return .failure(.failedSaveItem(key: key, error: error))
    }
  }
  
  func deleteItem(key: Key) -> Result<Void, DeleteError> {
    let url = folderPath.appendingPathComponent(key.description)
    guard fileManager.fileExists(atPath: url.path) else {
      return .failure(.noItem(key: key))
    }
    do {
      try fileManager.removeItem(at: url)
      return .success(())
    } catch {
      return .failure(.failedDeleteItem(key: key, error: error))
    }
  }
}

private extension FileSystemVault {
  var folderPath: URL {
    let folderName = String(describing: T.self)
    let folderPath = directory.appendingPathComponent(
      folderName,
      isDirectory: true
    )
    return folderPath
  }
  
  func createFolderIfNeeded(url: URL) throws {
    let path = url.path
    guard !fileManager.fileExists(atPath: path) else { return }
    try fileManager.createDirectory(
      atPath: path,
      withIntermediateDirectories: true
    )
  }
  
  func load(filename: String) throws -> T {
    let url = folderPath.appendingPathComponent(filename)
    let data = try Data(contentsOf: url)
    let item = try decoder.decode(T.self, from: data)
    return item
  }
}
