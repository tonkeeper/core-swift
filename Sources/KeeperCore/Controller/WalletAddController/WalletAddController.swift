import Foundation
import CoreComponents
import TonSwift

public final class WalletAddController {

  private let walletsStoreUpdate: WalletsStoreUpdate
  private let mnemonicRepositoty: WalletMnemonicRepository
  
  init(walletsStoreUpdate: WalletsStoreUpdate,
       mnemonicRepositoty: WalletMnemonicRepository) {
    self.walletsStoreUpdate = walletsStoreUpdate
    self.mnemonicRepositoty = mnemonicRepositoty
  }
  
  public func createWallet(metaData: WalletMetaData) throws {
    let mnemonic = try Mnemonic(mnemonicWords: TonSwift.Mnemonic.mnemonicNew(wordsCount: 24))
    let keyPair = try TonSwift.Mnemonic.mnemonicToPrivateKey(
      mnemonicArray: mnemonic.mnemonicWords
    )
    let walletIdentity = WalletIdentity(
      network: .mainnet,
      kind: .Regular(keyPair.publicKey)
    )
    let wallet = Wallet(
      identity: walletIdentity,
      metaData: metaData,
      contractVersion: .v4R2)
    
    try mnemonicRepositoty.saveMnemonic(mnemonic, forWallet: wallet)
    try walletsStoreUpdate.addWallets([wallet])
    
    try walletsStoreUpdate.makeWalletActive(wallet)
  }
}
