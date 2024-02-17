import Foundation
import CoreComponents

public final class PasscodeConfirmationController {
  
  private let passcodeRepository: PasscodeRepository
  
  init(passcodeRepository: PasscodeRepository) {
    self.passcodeRepository = passcodeRepository
  }
  
  public func validatePasscodeInput(_ passcodeInput: String) -> Bool {
    do {
      let passcode = try Passcode(value: passcodeInput)
      let storedPasscode = try passcodeRepository.getPasscode()
      return passcode == storedPasscode
    } catch {
      return false
    }
  }
}
