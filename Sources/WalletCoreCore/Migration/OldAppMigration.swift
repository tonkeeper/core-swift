import Foundation

public struct OldAppMigration {
    private let keeperInfoService: KeeperInfoService
    private let oldKeeperInfoService: KeeperInfoService
    private let mnemonicRepository: WalletMnemonicRepository
    private let oldMnemonicRepository: WalletMnemonicRepository
    
    init(keeperInfoService: KeeperInfoService,
         oldKeeperInfoService: KeeperInfoService,
         mnemonicRepository: WalletMnemonicRepository,
         oldMnemonicRepository: WalletMnemonicRepository) {
        self.keeperInfoService = keeperInfoService
        self.oldKeeperInfoService = oldKeeperInfoService
        self.mnemonicRepository = mnemonicRepository
        self.oldMnemonicRepository = oldMnemonicRepository
    }
    
    public func migrateIfNeeded() {
        do {
            let oldKeeperInfo = try oldKeeperInfoService.getKeeperInfo()
            try keeperInfoService.saveKeeperInfo(oldKeeperInfo)
            let wallets = oldKeeperInfo.wallets
            for wallet in wallets {
                let mnemonic = try oldMnemonicRepository.getMnemonic(wallet: wallet)
                try mnemonicRepository.saveMnemonic(mnemonic, for: wallet)
            }
            print("dsd")
        } catch {
            print("dsd")
        }
    }
}
