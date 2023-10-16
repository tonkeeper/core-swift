//
//  FiatMethodsController.swift
//
//
//  Created by Grigory on 14.10.23..
//

import Foundation
import CryptoKit
import TonSwift

public actor FiatMethodsController {
    private let fiatMethodsService: FiatMethodsService
    private let walletProvider: WalletProvider
    private let configurationController: ConfigurationController
    
    private var sectionsModels = [[FiatMethodViewModel]]()
    
    init(fiatMethodsService: FiatMethodsService,
         walletProvider: WalletProvider,
         configurationController: ConfigurationController) {
        self.fiatMethodsService = fiatMethodsService
        self.walletProvider = walletProvider
        self.configurationController = configurationController
    }
    
    public func getFiatMethods() async throws -> [[FiatMethodViewModel]] {
        let fiatMethods = try await fiatMethodsService.getFiatMethods()
        sectionsModels = mapFiatMethods(fiatMethods: fiatMethods)
        return sectionsModels
    }
    
    public func loadFiatMethods() async throws -> [[FiatMethodViewModel]] {
        let fiatMethods = try await fiatMethodsService.loadFiatMethods()
        sectionsModels = mapFiatMethods(fiatMethods: fiatMethods)
        return sectionsModels
    }
    
    public func urlForMethod(at section: Int, item: Int) async -> URL? {
        guard sectionsModels.count > section else { return nil }
        let sectionModel = sectionsModels[section]
        guard sectionModel.count > item else { return nil }
        let itemModel = sectionModel[item]
        return await handleMethodItem(itemModel)
    }
}

private extension FiatMethodsController {
    func mapFiatMethods(fiatMethods: FiatMethods) -> [[FiatMethodViewModel]] {
        let sections = fiatMethods.categories.map { category in
            category.items.compactMap { item -> FiatMethodViewModel? in
                guard fiatMethods.defaultLayout.methods.contains(item.id) else { return nil }
                return FiatMethodViewModel(
                    id: item.id,
                    title: item.title,
                    description: item.description,
                    token: item.badge,
                    iconURL: item.iconURL,
                    buttonTitle: item.actionButton.title,
                    buttonUrl: item.actionButton.url
                )
            }
        }
        return sections
    }
    
    
    func handleMethodItem(_ item: FiatMethodViewModel) async -> URL? {
        let contractBuilder = WalletContractBuilder()
        guard var urlString = item.buttonUrl,
              let wallet = try? walletProvider.activeWallet,
              let publicKey = try? wallet.publicKey,
              let addressString = try? contractBuilder
            .walletContract(with: publicKey, contractVersion: wallet.contractVersion)
            .address()
            .toString(bounceable: false) else { return nil }
        
        let currency = wallet.currency
        
        let currTo: String
        switch item.id {
        case "neocrypto":
            currTo = "TON"
        case "mercuryo":
            await handleUrlForMercuryo(urlString: &urlString, walletAddress: addressString)
            currTo = "TONCOIN"
        default:
            return nil
        }
        
        urlString = urlString.replacingOccurrences(of: "{CUR_FROM}", with: currency.code)
        urlString = urlString.replacingOccurrences(of: "{CUR_TO}", with: currTo)
        urlString = urlString.replacingOccurrences(of: "{ADDRESS}", with: addressString)
        
        guard let url = URL(string: urlString) else { return nil }
        return url
    }
    
    func handleUrlForMercuryo(urlString: inout String,
                              walletAddress: String) async {
        urlString = urlString.replacingOccurrences(of: "{TX_ID}", with: "mercuryo_\(UUID().uuidString)")
        
        let mercuryoSecret = await configurationController.configuration.mercuryoSecret ?? ""
        guard let signature = (walletAddress + mercuryoSecret).data(using: .utf8)?.sha256().hexString() else { return }
        urlString += "&signature=\(signature)"
    }
}
