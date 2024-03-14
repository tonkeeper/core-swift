//
//  FiatMethodsController.swift
//
//
//  Created by Grigory on 14.10.23..
//

import Foundation
import CryptoKit
import TonSwift
import WalletCoreCore

public actor FiatMethodsController {
    private let fiatMethodsService: FiatMethodsService
    private let locationService: LocationService
    private let walletProvider: WalletProvider
    private let configurationController: ConfigurationController
    
    private var sectionsModels = [[FiatMethodViewModel]]()
    
    init(fiatMethodsService: FiatMethodsService,
         walletProvider: WalletProvider,
         locationService: LocationService,
         configurationController: ConfigurationController) {
        self.fiatMethodsService = fiatMethodsService
        self.walletProvider = walletProvider
        self.locationService = locationService
        self.configurationController = configurationController
    }
    
    public func getFiatMethods() async throws -> [[FiatMethodViewModel]] {
        let fiatMethods = try await fiatMethodsService.getFiatMethods()
        sectionsModels = mapFiatMethods(fiatMethods: fiatMethods)
        return sectionsModels
    }
    
    public func loadFiatMethods(isMarketRegionPickerAvailable: Bool) async throws -> [[FiatMethodViewModel]] {
        if !isMarketRegionPickerAvailable {
            return try await loadFiatMethodsByLocationRequired()
        } else {
            return try await loadDefaultFiatMethods()
        }
    }
    
    public func urlForMethod(_ method: FiatMethodViewModel) async -> URL? {
        return await handleMethodItem(method)
    }
    
    public func fiatMethodViewModel(at section: Int, item: Int) async -> FiatMethodViewModel? {
        guard sectionsModels.count > section else { return nil }
        let sectionModel = sectionsModels[section]
        guard sectionModel.count > item else { return nil }
        return sectionModel[item]
    }
}

private extension FiatMethodsController {
    func mapFiatMethods(fiatMethods: FiatMethods) -> [[FiatMethodViewModel]] {
        let sections = fiatMethods.categories.compactMap { category -> [FiatMethodViewModel]? in
            let models = category.items.compactMap { item -> FiatMethodViewModel? in
                guard availableFiatMethods.contains(item.id) else { return nil }
                return FiatMethodViewModel(
                    id: item.id,
                    title: item.title,
                    description: item.description,
                    token: item.badge,
                    iconURL: item.iconURL,
                    actionButton: .init(title: item.actionButton.title, url: item.actionButton.url),
                    infoButtons: item.infoButtons.map { .init(title: $0.title, url: $0.url) }
                )
            }
            guard !models.isEmpty else { return nil }
            return models
        }
        return sections
    }
    
    
    func handleMethodItem(_ item: FiatMethodViewModel) async -> URL? {
        let contractBuilder = WalletContractBuilder()
        guard var urlString = item.actionButton?.url,
              let wallet = try? walletProvider.activeWallet,
              let publicKey = try? wallet.publicKey,
              let addressString = try? contractBuilder
            .walletContract(with: publicKey, contractVersion: wallet.contractVersion)
            .address()
            .toString(bounceable: false) else { return nil }
        
        let currency = wallet.currency
        
        let currTo: String
        switch item.id {
        case "neocrypto", "moonpay":
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
    
    func loadFiatMethodsByLocationRequired() async throws -> [[FiatMethodViewModel]] {
        do {
            let countryCode = try await locationService.getCountryCodeByIp()
            let fiatMethods = try await fiatMethodsService.loadFiatMethods(countryCode: countryCode)
            sectionsModels = mapFiatMethods(fiatMethods: fiatMethods)
            return sectionsModels
        } catch {
            return []
        }
    }
    
    func loadDefaultFiatMethods() async throws -> [[FiatMethodViewModel]] {
        let fiatMethods = try await fiatMethodsService.loadFiatMethods(countryCode: nil)
        sectionsModels = mapFiatMethods(fiatMethods: fiatMethods)
        return sectionsModels
    }
    
    private var availableFiatMethods: [FiatMethodItem.ID] {
        ["mercuryo", "neocrypto", "moonpay"]
    }
}
