import Foundation

public final class PasscodeAssembly {
  
  let repositoriesAssembly: RepositoriesAssembly
  
  init(repositoriesAssembly: RepositoriesAssembly) {
    self.repositoriesAssembly = repositoriesAssembly
  }
  
  public func passcodeCreateController() -> PasscodeCreateController {
    PasscodeCreateController(passcodeRepository: repositoriesAssembly.passcodeRepository())
  }
  
  public func passcodeConfirmationController() -> PasscodeConfirmationController {
    PasscodeConfirmationController(passcodeRepository: repositoriesAssembly.passcodeRepository())
  }
}
