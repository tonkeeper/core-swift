import Foundation
import CoreComponents
import TonSwift

enum WalletListUpdaterEvent {
  case didAddWallet
}

protocol WalletListUpdaterObserver: AnyObject {
  func didGetWalletListUpdaterEvent(_ event: WalletListUpdaterEvent)
}

final class WalletListUpdater {
  private let keeperInfoService: KeeperInfoService
  private let mnemonicRepository: WalletMnemonicRepository
  
  init(keeperInfoService: KeeperInfoService,
       mnemonicRepository: WalletMnemonicRepository) {
    self.keeperInfoService = keeperInfoService
    self.mnemonicRepository = mnemonicRepository
  }
  
  func addRegularWallet(mnemonic: CoreComponents.Mnemonic,
                        metaData: WalletMetaData,
                        network: Network) throws {
    try createWallet(
      mnemonic: mnemonic,
      metaData: metaData,
      network: network)
    notifyObservers(event: .didAddWallet)
  }

  private var observers = [WalletListUpdaterWrapper]()
  
  struct WalletListUpdaterWrapper {
    weak var observer: WalletListUpdaterObserver?
  }
  
  func addObserver(_ observer: WalletListUpdaterObserver) {
    removeNilObservers()
    observers = observers + CollectionOfOne(WalletListUpdaterWrapper(observer: observer))
  }
  
  func removeObserver(_ observer: WalletListUpdaterObserver) {
    removeNilObservers()
    observers = observers.filter { $0.observer !== observer }
  }
}

private extension WalletListUpdater {
  func createWallet(mnemonic: CoreComponents.Mnemonic,
                    metaData: WalletMetaData,
                    network: Network) throws {
    let keyPair = try TonSwift.Mnemonic.mnemonicToPrivateKey(
      mnemonicArray: mnemonic.mnemonicWords
    )
    let identity = WalletIdentity(
      network: network,
      kind: .Regular(keyPair.publicKey)
    )
    let wallet = Wallet(identity: identity, metaData: metaData)
    try mnemonicRepository.saveMnemonic(mnemonic, forWallet: wallet)
    try keeperInfoService.addWallet(
      wallet,
      setActive: true
    )
  }
  
  func removeNilObservers() {
    observers = observers.filter { $0.observer != nil }
  }
  
  func notifyObservers(event: WalletListUpdaterEvent) {
    observers.forEach { $0.observer?.didGetWalletListUpdaterEvent(event) }
  }
}
