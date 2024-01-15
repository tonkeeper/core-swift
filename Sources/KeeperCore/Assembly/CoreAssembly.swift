import Foundation
import CoreComponents

struct CoreAssembly {
  private let cacheURL: URL
  private let sharedCacheURL: URL
  
  init(cacheURL: URL, sharedCacheURL: URL) {
    self.cacheURL = cacheURL
    self.sharedCacheURL = sharedCacheURL
  }
  
  func mnemonicRepository() -> WalletMnemonicRepository {
    mnemonicVault()
  }
  
  func keeperInfoRepository() -> KeeperInfoRepository {
    sharedFileSystemVault()
  }

  func fileSystemVault<T, K>() -> FileSystemVault<T, K> {
    return FileSystemVault(fileManager: fileManager, directory: cacheURL)
  }
  
  func sharedFileSystemVault<T, K>() -> FileSystemVault<T, K> {
    return FileSystemVault(fileManager: fileManager, directory: sharedCacheURL)
  }
}

private extension CoreAssembly {
  var fileManager: FileManager {
    .default
  }
  
  var keychainVault: KeychainVault {
    KeychainVaultImplementation(keychain: keychain)
  }
  
  var keychain: Keychain {
    KeychainImplementation()
  }
  
  func mnemonicVault() -> MnemonicVault {
    MnemonicVault(keychainVault: keychainVault, accessGroup: nil)
  }
}
