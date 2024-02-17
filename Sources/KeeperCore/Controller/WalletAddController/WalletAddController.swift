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
      kind: .Regular(keyPair.publicKey, .v4R2)
    )
    let wallet = Wallet(
      identity: walletIdentity,
      metaData: metaData,
      setupSettings: WalletSetupSettings(backupDate: nil)
    )
    
    try mnemonicRepositoty.saveMnemonic(mnemonic, forWallet: wallet)
    try walletsStoreUpdate.addWallets([wallet])
    
    try walletsStoreUpdate.makeWalletActive(wallet)
  }
  
  public func importWallets(phrase: [String],
                            revisions: [WalletContractVersion],
                            metaData: WalletMetaData) throws {
    let mnemonic = try Mnemonic(mnemonicWords: phrase)
    let keyPair = try TonSwift.Mnemonic.mnemonicToPrivateKey(
      mnemonicArray: mnemonic.mnemonicWords
    )
    
    let addPostfix = revisions.count > 1

    let wallets = revisions.map { revision in
      let label = addPostfix ? "\(metaData.label) \(revision.rawValue)" : metaData.label
      let revisionMetaData = WalletMetaData(
        label: label,
        colorIdentifier: metaData.colorIdentifier,
        emoji: metaData.emoji
      )
      
      let walletIdentity = WalletIdentity(
        network: .mainnet,
        kind: .Regular(keyPair.publicKey, revision)
      )
      
      return Wallet(
        identity: walletIdentity,
        metaData: revisionMetaData,
        setupSettings: WalletSetupSettings(backupDate: Date()))
    }

    try wallets.forEach { wallet in
      try mnemonicRepositoty.saveMnemonic(mnemonic, forWallet: wallet)
    }
    try walletsStoreUpdate.addWallets(wallets)
    try walletsStoreUpdate.makeWalletActive(wallets[0])
  }
}
