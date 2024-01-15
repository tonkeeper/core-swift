import Foundation

final class ServicesAssembly {
  
  private let coreAssembly: CoreAssembly
  
  init(coreAssembly: CoreAssembly) {
    self.coreAssembly = coreAssembly
  }
  
  func keeperInfoService() -> KeeperInfoService {
    KeeperInfoServiceImplementation(keeperInfoRepository: coreAssembly.keeperInfoRepository())
  }
}
