//
//  TonConnectAssembly.swift
//  
//
//  Created by Grigory Serebryanyy on 25.10.2023.
//

import Foundation
import WalletCoreCore

final class TonConnectAssembly {
    private let coreAssembly: CoreAssembly
    private let apiAssembly: APIAssembly
    private let sendAssembly: SendAssembly
    private let servicesAssembly: ServicesAssembly
    private let formattersAssembly: FormattersAssembly
    private let cacheURL: URL
    private let keychainGroup: String
    
    init(coreAssembly: CoreAssembly,
         apiAssembly: APIAssembly,
         sendAssembly: SendAssembly,
         servicesAssembly: ServicesAssembly,
         formattersAssembly: FormattersAssembly,
         cacheURL: URL,
         keychainGroup: String) {
        self.coreAssembly = coreAssembly
        self.apiAssembly = apiAssembly
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
            walletProvider: coreAssembly.walletProvider,
            appsVault: appsVault,
            mnemonicRepository: coreAssembly.walletMnemonicRepository
        )
        Task { await controller.addObserver(tonConnectEventsDaemon) }
        return controller
    }
    
    func tonConnectConfirmationController() -> TonConnectConfirmationController {
        TonConnectConfirmationController(
            sendService: servicesAssembly.sendService,
            apiClient: apiAssembly.tonConnectAPIClient(),
            rateService: servicesAssembly.ratesService,
            collectiblesService: servicesAssembly.collectiblesService,
            walletProvider: coreAssembly.walletProvider,
            tonConnectConfirmationMapper: tonConnectConfirmationMapper
        )
    }
    
    lazy var tonConnectEventsDaemon: TonConnectEventsDaemon = {
        TonConnectEventsDaemon(
            walletProvider: coreAssembly.walletProvider,
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
        TonConnectAppsVault(keychainVault: coreAssembly.keychainVault,
                            accessGroup: keychainGroup)
    }
    
    func localRepository<T: LocalStorable>(cacheURL: URL) -> any LocalRepository<T> {
        LocalDiskRepository(fileManager: coreAssembly.fileManager,
                            directory: cacheURL,
                            encoder: JSONEncoder(),
                            decoder: JSONDecoder())
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
