import Foundation

public struct PasscodeVault {
  public enum Error: Swift.Error {
    case failedToLoadPasscode
    case failedToSavePasscode
  }
  
  private let keychainVault: KeychainVault
  
  init(keychainVault: KeychainVault) {
    self.keychainVault = keychainVault
  }
  
  func load() throws -> Passcode {
    try keychainVault.readValue(Passcode.query())
  }
  
  func save(_ passcode: Passcode) throws {
    try keychainVault.saveValue(passcode, to: Passcode.query())
  }
}

private extension Passcode {
    static func query() throws -> KeychainQueryable {
        KeychainGenericPasswordItem(service: "PasscodeVault",
                                    account: "Passcode",
                                    accessGroup: nil,
                                    accessible: .whenUnlockedThisDeviceOnly)
    }
}
