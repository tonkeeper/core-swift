import Foundation

public final class SettingsSecurityController {
  
  private let securityStore: SecurityStore
  
  init(securityStore: SecurityStore) {
    self.securityStore = securityStore
  }
  
  public var isBiometryEnabled: Bool {
    securityStore.isBiometryEnabled
  }
  
  public func setIsBiometryEnabled(_ isBiometryEnabled: Bool) -> Bool {
    do {
      try securityStore.setIsBiometryEnabled(isBiometryEnabled)
      return isBiometryEnabled
    } catch {
      return !isBiometryEnabled
    }
  }
}
