//
//  TonConnectAssembly.swift
//  
//
//  Created by Grigory Serebryanyy on 25.10.2023.
//

import Foundation

final class TonConnectAssembly {
    private let coreAssembly: CoreAssembly
    private let apiAssembly: APIAssembly
    private let keeperAssembly: KeeperAssembly
    private let sendAssembly: SendAssembly
    private let servicesAssembly: ServicesAssembly
    private let formattersAssembly: FormattersAssembly
    private let cacheURL: URL
    private let keychainGroup: String
    
    init(coreAssembly: CoreAssembly,
         apiAssembly: APIAssembly,
         keeperAssembly: KeeperAssembly,
         sendAssembly: SendAssembly,
         servicesAssembly: ServicesAssembly,
         formattersAssembly: FormattersAssembly,
         cacheURL: URL,
         keychainGroup: String) {
        self.coreAssembly = coreAssembly
        self.apiAssembly = apiAssembly
        self.keeperAssembly = keeperAssembly
        self.sendAssembly = sendAssembly
        self.servicesAssembly = servicesAssembly
        self.formattersAssembly = formattersAssembly
        self.cacheURL = cacheURL
        self.keychainGroup = keychainGroup
    }
    
    func tonConnectDeeplinkProcessor() -> TonConnectDeeplinkProcessor {
        TonConnectDeeplinkProcessor(manifestLoader: manifestLoader)
    }
    
    func tonConnectController(parameters: TonConnectParameters,
                              manifest: TonConnectManifest) -> TonConnectController {
        let controller = TonConnectController(
            parameters: parameters,
            manifest: manifest,
            apiClient: apiAssembly.tonConnectAPIClient(),
            walletProvider: keeperAssembly.keeperController,
            appsVault: appsVault,
            mnemonicVault: coreAssembly.keychainMnemonicVault(keychainGroup: keychainGroup)
        )
        Task { await controller.addObserver(tonConnectEventsDaemon) }
        return controller
    }
    
    func tonConnectConfirmationController() -> TonConnectConfirmationController {
        TonConnectConfirmationController(
            sendMessageBuilder: sendAssembly.sendMessageBuilder(),
            sendService: servicesAssembly.sendService,
            apiClient: apiAssembly.tonConnectAPIClient(),
            rateService: servicesAssembly.ratesService,
            walletProvider: keeperAssembly.keeperController,
            tonConnectConfirmationMapper: tonConnectConfirmationMapper
        )
    }
    
    lazy var tonConnectEventsDaemon: TonConnectEventsDaemon = {
        TonConnectEventsDaemon(
            walletProvider: keeperAssembly.keeperController,
            appsVault: appsVault,
            apiClient: apiAssembly.tonConnectAPIClient(),
            localRepository: localRepository(cacheURL: cacheURL))
    }()
}

private extension TonConnectAssembly {
    var manifestLoader: TonConnectManifestLoader {
        TonConnectManifestLoader(urlSession: urlSession)
    }
    
    var urlSession: URLSession {
        URLSession(configuration: urlSessionConfiguration)
    }
    
    var urlSessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 60
        return configuration
    }
    
    var appsVault: TonConnectAppsVault {
        TonConnectAppsVault(
            keychainManager: coreAssembly.keychainManager,
            keychainGroup: keychainGroup
        )
    }
    
    func localRepository<T: LocalStorable>(cacheURL: URL) -> any LocalRepository<T> {
        LocalDiskRepository(fileManager: coreAssembly.fileManager,
                            directory: cacheURL,
                            encoder: coreAssembly.encoder,
                            decoder: coreAssembly.decoder)
    }
    
    func sendMessageBuilder(walletProvider: WalletProvider,
                            keychainGroup: String,
                            sendService: SendService) -> SendMessageBuilder {
        SendMessageBuilder(walletProvider: walletProvider,
                           mnemonicVault: coreAssembly.keychainMnemonicVault(keychainGroup: keychainGroup),
                           sendService: sendService)
    }
    
    var accountEventMapper: AccountEventMapper {
        AccountEventMapper(dateFormatter: formattersAssembly.dateFormatter,
                           amountFormatter: formattersAssembly.amountFormatter,
                           intAmountFormatter: formattersAssembly.intAmountFormatter,
                           amountMapper: AmountAccountEventActionAmountMapper(amountFormatter: formattersAssembly.amountFormatter))
    }
    
    var tonConnectConfirmationMapper: TonConnectConfirmationMapper {
        TonConnectConfirmationMapper(accountEventMapper: accountEventMapper,
                                     amountFormatter: formattersAssembly.amountFormatter)
    }
}
