//
//  SendAssembly.swift
//  
//
//  Created by Grigory on 5.7.23..
//

import Foundation
import TonSwift
import TonAPI

final class SendAssembly {
    let coreAssembly: CoreAssembly
    let apiAssembly: APIAssembly
    let servicesAssembly: ServicesAssembly
    let keeperAssembly: KeeperAssembly
    let balanceAssembly: WalletBalanceAssembly
    let formattersAssembly: FormattersAssembly
    let cacheURL: URL
    let keychainGroup: String
    
    init(coreAssembly: CoreAssembly,
         apiAssembly: APIAssembly,
         servicesAssembly: ServicesAssembly,
         keeperAssembly: KeeperAssembly,
         balanceAssembly: WalletBalanceAssembly,
         formattersAssembly: FormattersAssembly,
         cacheURL: URL,
         keychainGroup: String) {
        self.coreAssembly = coreAssembly
        self.apiAssembly = apiAssembly
        self.servicesAssembly = servicesAssembly
        self.keeperAssembly = keeperAssembly
        self.balanceAssembly = balanceAssembly
        self.formattersAssembly = formattersAssembly
        self.cacheURL = cacheURL
        self.keychainGroup = keychainGroup
    }
    
    func sendInputController() -> SendInputController {
        return SendInputController(bigIntAmountFormatter: formattersAssembly.bigIntAmountFormatter,
                                   amountFormatter: formattersAssembly.amountFormatter,
                                   ratesService: servicesAssembly.ratesService,
                                   balanceService: servicesAssembly.walletBalanceService,
                                   tokenMapper: sendTokenMapper(),
                                   walletProvider: keeperAssembly.keeperController,
                                   rateConverter: RateConverter())
    }
    
    func tokenSendController(tokenTransferModel: TokenTransferModel,
                             recipient: Recipient,
                             comment: String?,
                             walletProvider: WalletProvider,
                             keychainGroup: String) -> SendController {
        return TokenSendController(
            tokenTransferModel: tokenTransferModel,
            recipient: recipient,
            comment: comment,
            walletProvider: walletProvider,
            sendService: servicesAssembly.sendService,
            rateService: servicesAssembly.ratesService,
            sendMessageBuilder: sendMessageBuilder(),
            intAmountFormatter: formattersAssembly.intAmountFormatter,
            amountFormatter: formattersAssembly.amountFormatter)
    }
    
    func nftSendController(nftAddress: Address,
                           recipient: Recipient,
                           comment: String?,
                           walletProvider: WalletProvider,
                           keychainGroup: String) -> SendController {
        return NFTSendController(
            nftAddress: nftAddress,
            recipient: recipient,
            comment: comment,
            walletProvider: walletProvider,
            sendService: servicesAssembly.sendService,
            rateService: servicesAssembly.ratesService,
            collectibleService: servicesAssembly.collectiblesService,
            sendMessageBuilder: sendMessageBuilder(),
            amountFormatter: formattersAssembly.amountFormatter,
            bigIntAmountFormatter: formattersAssembly.bigIntAmountFormatter)
    }
    
    func sendRecipientController() -> SendRecipientController {
        SendRecipientController(domainService: servicesAssembly.dnsService,
                                accountInfoService: servicesAssembly.accountInfoService)
    }
    
    func sendMessageBuilder() -> SendMessageBuilder {
        SendMessageBuilder(walletProvider: keeperAssembly.keeperController,
                           mnemonicVault: coreAssembly.keychainMnemonicVault(keychainGroup: keychainGroup),
                           sendService: servicesAssembly.sendService)
    }
}

private extension SendAssembly {
    func sendTokenMapper() -> SendTokenMapper {
        SendTokenMapper(intAmountFormatter: formattersAssembly.intAmountFormatter,
                        decimalAmountFormatter: formattersAssembly.decimalAmountFormatter,
                        amountFormatter: formattersAssembly.amountFormatter)
    }
}
