import Foundation
import CoreComponents
import TonSwift

public final class WalletAddController {

  private let walletListUpdater: WalletListUpdater
  
  init(walletListUpdater: WalletListUpdater) {
    self.walletListUpdater = walletListUpdater
  }
  
  public func createWallet(metaData: WalletMetaData,
                           isTestnet: Bool = false) throws {
    let mnemonic = try Mnemonic(mnemonicWords: Mnemonic.mnemonicNew(wordsCount: 24))
    try walletListUpdater.addRegularWallet(
      mnemonic: mnemonic,
      metaData: metaData,
      network: isTestnet ? .testnet : .mainnet)
  }
  
  public func addWallet(phrase: [String],
                        metaData: WalletMetaData,
                        isTestnet: Bool = false) throws {
    let mnemonic = try CoreComponents.Mnemonic(mnemonicWords: phrase)
    try walletListUpdater.addRegularWallet(
      mnemonic: mnemonic,
      metaData: metaData,
      network: isTestnet ? .testnet : .mainnet)
  }
}
