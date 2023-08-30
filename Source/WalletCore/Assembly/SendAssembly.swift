//
//  SendAssembly.swift
//  
//
//  Created by Grigory on 5.7.23..
//

import Foundation
import TonAPI

final class SendAssembly {
    
    let formattersAssembly: FormattersAssembly
    let ratesAssembly: RatesAssembly
    let balanceAssembly: WalletBalanceAssembly
    let coreAssembly: CoreAssembly
    
    init(formattersAssembly: FormattersAssembly,
         ratesAssembly: RatesAssembly,
         balanceAssembly: WalletBalanceAssembly,
         coreAssembly: CoreAssembly) {
        self.formattersAssembly = formattersAssembly
        self.ratesAssembly = ratesAssembly
        self.balanceAssembly = balanceAssembly
        self.coreAssembly = coreAssembly
    }
    
    func sendInputController(api: API,
                             cacheURL: URL,
                             walletProvider: WalletProvider) -> SendInputController {
        return SendInputController(bigIntAmountFormatter: formattersAssembly.bigIntAmountFormatter,
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
                             walletProvider: WalletProvider) -> SendController {
        let sendService = sendService(api: api)
        return TokenSendController(
            tokenTransferModel: tokenTransferModel,
            recipient: recipient,
            comment: comment,
            sendService: sendService,
            rateService: ratesAssembly.ratesService(api: api, cacheURL: cacheURL),
            sendMessageBuilder: sendMessageBuilder(walletProvider: walletProvider, sendService: sendService),
            intAmountFormatter: formattersAssembly.intAmountFormatter,
            bigIntAmountFormatter: formattersAssembly.bigIntAmountFormatter)
    }
    
    func nftSendController(_ nft: Collectible,
                           recipient: Recipient,
                           comment: String?,
                           walletProvider: WalletProvider) -> SendController {
        return NFTSendController(collectible: nft)
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
                        bigIntAmountFormatter: formattersAssembly.bigIntAmountFormatter)
    }
    
    func sendMessageBuilder(walletProvider: WalletProvider, 
                            sendService: SendService) -> SendMessageBuilder {
        SendMessageBuilder(walletProvider: walletProvider,
                           keychainManager: coreAssembly.keychainManager,
                           sendService: sendService)
    }
}
