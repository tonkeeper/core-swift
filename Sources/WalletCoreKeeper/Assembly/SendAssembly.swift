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
    let balanceAssembly: WalletBalanceAssembly
    let formattersAssembly: FormattersAssembly
    let cacheURL: URL
    let keychainGroup: String
    
    init(coreAssembly: CoreAssembly,
         apiAssembly: APIAssembly,
         servicesAssembly: ServicesAssembly,
         balanceAssembly: WalletBalanceAssembly,
         formattersAssembly: FormattersAssembly,
         cacheURL: URL,
         keychainGroup: String) {
        self.coreAssembly = coreAssembly
        self.apiAssembly = apiAssembly
        self.servicesAssembly = servicesAssembly
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
                                   walletProvider: coreAssembly.walletProvider,
                                   rateConverter: RateConverter())
    }
    
    func tokenSendController(tokenTransferModel: TokenTransferModel,
                             recipient: Recipient,
                             comment: String?,
                             keychainGroup: String) -> SendController {
        return TokenSendController(
            tokenTransferModel: tokenTransferModel,
            recipient: recipient,
            comment: comment,
            walletProvider: coreAssembly.walletProvider,
            sendService: servicesAssembly.sendService,
            rateService: servicesAssembly.ratesService,
            intAmountFormatter: formattersAssembly.intAmountFormatter,
            amountFormatter: formattersAssembly.amountFormatter)
    }
    
    func nftSendController(nftAddress: Address,
                           recipient: Recipient,
                           comment: String?,
                           keychainGroup: String) -> SendController {
        return NFTSendController(
            nftAddress: nftAddress,
            recipient: recipient,
            comment: comment,
            walletProvider: coreAssembly.walletProvider,
            sendService: servicesAssembly.sendService,
            rateService: servicesAssembly.ratesService,
            collectibleService: servicesAssembly.collectiblesService,
            amountFormatter: formattersAssembly.amountFormatter,
            bigIntAmountFormatter: formattersAssembly.bigIntAmountFormatter)
    }
    
    func sendRecipientController() -> SendRecipientController {
        SendRecipientController(domainService: servicesAssembly.dnsService,
                                accountInfoService: servicesAssembly.accountInfoService)
    }
}

private extension SendAssembly {
    func sendTokenMapper() -> SendTokenMapper {
        SendTokenMapper(intAmountFormatter: formattersAssembly.intAmountFormatter,
                        decimalAmountFormatter: formattersAssembly.decimalAmountFormatter,
                        amountFormatter: formattersAssembly.amountFormatter)
    }
}
