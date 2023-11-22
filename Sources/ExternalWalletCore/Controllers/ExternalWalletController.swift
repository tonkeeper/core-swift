//
//  ExternalWalletController.swift
//
//
//  Created by Grigory Serebryanyy on 22.11.2023.
//

import Foundation
import WalletCoreCore
import TonSwift

enum ExternalWalletControllerError: Swift.Error {
    case incorrectUrl
    case noWalletToSignTransfer
    case alreadyProcessingTransfer
    case failedToBuildWalletExportURL
}

public enum ExternalWalletControllerAction {
    case signTransfer(wallet: Wallet, boc: String)
}

public protocol ExternalWalletController {
    func processUrl(_ url: URL) throws -> ExternalWalletControllerAction
    func reset()
    func exportWalletUrl(_ wallet: Wallet) throws -> URL
}

public final class ExternalWalletControllerImplementation: ExternalWalletController {
    enum State {
        case idle
        case signing
    }
    
    private var state: State = .idle
    
    private let walletProvider: WalletProvider
    private let urlParser: ExternalWalletURLParser
    private let urlBuilder: ExternalWalletURLBuilder
    
    init(walletProvider: WalletProvider,
         urlParser: ExternalWalletURLParser,
         urlBuilder: ExternalWalletURLBuilder) {
        self.walletProvider = walletProvider
        self.urlParser = urlParser
        self.urlBuilder = urlBuilder
    }
    
    public func processUrl(_ url: URL) throws -> ExternalWalletControllerAction {
        let action: ExternalWalletAction
        do {
            action = try urlParser.parseUrl(url)
        } catch {
            throw ExternalWalletControllerError.incorrectUrl
        }
        
        switch action {
        case .signTransfer(let publicKey, let boc):
            let walletsToSign = walletProvider
                .wallets
                .filter { $0.isRegular }
            guard let wallet = walletsToSign.first(where: { (try? $0.publicKey.data) == publicKey.data }) else {
                throw ExternalWalletControllerError.noWalletToSignTransfer
            }
            guard state != .signing else {
                throw ExternalWalletControllerError.alreadyProcessingTransfer
            }
            state = .signing
            return .signTransfer(wallet: wallet, boc: boc)
        }
    }
    
    public func reset() {
        state = .idle
    }
    
    public func exportWalletUrl(_ wallet: Wallet) throws -> URL {
        do {
            return try urlBuilder.buildWalletExportUrl(wallet: wallet)
        } catch {
            throw ExternalWalletControllerError.failedToBuildWalletExportURL
        }
    }
}
