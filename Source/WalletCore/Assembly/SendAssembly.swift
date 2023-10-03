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
    
    let formattersAssembly: FormattersAssembly
    let ratesAssembly: RatesAssembly
    let balanceAssembly: WalletBalanceAssembly
    let servicesAssembly: ServicesAssembly
    let coreAssembly: CoreAssembly
    
    init(formattersAssembly: FormattersAssembly,
         ratesAssembly: RatesAssembly,
         balanceAssembly: WalletBalanceAssembly,
         servicesAssembly: ServicesAssembly,
         coreAssembly: CoreAssembly) {
        self.formattersAssembly = formattersAssembly
        self.ratesAssembly = ratesAssembly
        self.balanceAssembly = balanceAssembly
        self.servicesAssembly = servicesAssembly
        self.coreAssembly = coreAssembly
    }
    
    func sendInputController(api: API,
                             cacheURL: URL,
                             walletProvider: WalletProvider) -> SendInputController {
        return SendInputController(bigIntAmountFormatter: formattersAssembly.bigIntAmountFormatter,
                                   amountFormatter: formattersAssembly.amountFormatter,
                                   ratesService: ratesAssembly.ratesService(api: api, cacheURL: cacheURL),
                                   balanceService: balanceAssembly.walletBalanceService(api: api, cacheURL: cacheURL),
                                   tokenMapper: sendTokenMapper(),
                                   walletProvider: walletProvider,
                                   rateConverter: RateConverter())
    }
    
    func tokenSendController(api: API,
                             cacheURL: URL,
                             tokenTransferModel: TokenTransferModel,
                             recipient: Recipient,
                             comment: String?,
                             walletProvider: WalletProvider,
                             keychainGroup: String) -> SendController {
        let sendService = sendService(api: api)
        return TokenSendController(
            tokenTransferModel: tokenTransferModel,
            recipient: recipient,
            comment: comment,
            walletProvider: walletProvider,
            sendService: sendService,
            rateService: ratesAssembly.ratesService(api: api, cacheURL: cacheURL),
            sendMessageBuilder: sendMessageBuilder(
                walletProvider: walletProvider,
                keychainGroup: keychainGroup,
                sendService: sendService),
            intAmountFormatter: formattersAssembly.intAmountFormatter,
            amountFormatter: formattersAssembly.amountFormatter)
    }
    
    func nftSendController(api: API,
                           cacheURL: URL,
                           nftAddress: Address,
                           recipient: Recipient,
                           comment: String?,
                           walletProvider: WalletProvider,
                           keychainGroup: String) -> SendController {
        let sendService = sendService(api: api)
        return NFTSendController(
            nftAddress: nftAddress,
            recipient: recipient,
            comment: comment,
            walletProvider: walletProvider,
            sendService: sendService,
            rateService: ratesAssembly.ratesService(api: api, cacheURL: cacheURL),
            collectibleService: servicesAssembly.collectiblesService,
            sendMessageBuilder: sendMessageBuilder(
                walletProvider: walletProvider,
                keychainGroup: keychainGroup,
                sendService: sendService),
            amountFormatter: formattersAssembly.amountFormatter,
            bigIntAmountFormatter: formattersAssembly.bigIntAmountFormatter)
    }
    
    func sendRecipientController(api: API) -> SendRecipientController {
        SendRecipientController(domainService: dnsService(api: api),
                                accountInfoService: accountInfoService(api: api))
    }
}

private extension SendAssembly {
    func sendService(api: API) -> SendService {
        SendServiceImplementation(api: api)
    }
    
    func dnsService(api: API) -> DNSService {
        DNSServiceImplementation(api: api)
    }
    
    func accountInfoService(api: API) -> AccountInfoService {
        AccountInfoServiceImplementation(api: api)
    }
    
    func sendTokenMapper() -> SendTokenMapper {
        SendTokenMapper(intAmountFormatter: formattersAssembly.intAmountFormatter,
                        decimalAmountFormatter: formattersAssembly.decimalAmountFormatter,
                        amountFormatter: formattersAssembly.amountFormatter)
    }
    
    func sendMessageBuilder(walletProvider: WalletProvider,
                            keychainGroup: String,
                            sendService: SendService) -> SendMessageBuilder {
        SendMessageBuilder(walletProvider: walletProvider,
                           keychainManager: coreAssembly.keychainManager,
                           keychainGroup: keychainGroup,
                           sendService: sendService)
    }
}
