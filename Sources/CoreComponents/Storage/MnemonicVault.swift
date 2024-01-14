import Foundation

struct MnemonicVault: KeyValueVault {
  typealias StoreValue = Mnemonic
  typealias StoreKey = String
  
  private let keychainVault: KeychainVault
  private let accessGroup: String?
  
  init(keychainVault: KeychainVault,
       accessGroup: String?) {
    self.keychainVault = keychainVault
    self.accessGroup = accessGroup
  }
  
  func saveValue(_ value: Mnemonic, for key: StoreKey) throws {
    try keychainVault.saveValue(value, to: query(key: key, accessGroup: accessGroup))
  }
  
  func deleteValue(for key: StoreKey) throws {
    try keychainVault.deleteItem(query(key: key, accessGroup: accessGroup))
  }
  
  func loadValue(key: StoreKey) throws -> Mnemonic {
    try keychainVault.readValue(query(key: key, accessGroup: accessGroup))
  }
  
  private func query(key: StoreKey,
                     accessGroup: String?) -> KeychainQueryable {
    KeychainGenericPasswordItem(service: "MnemonicVault",
                                account: key,
                                accessGroup: accessGroup,
                                accessible: .whenUnlockedThisDeviceOnly)
  }
}
