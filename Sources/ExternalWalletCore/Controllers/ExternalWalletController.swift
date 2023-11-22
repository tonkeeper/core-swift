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
}

public enum ExternalWalletControllerAction {
    case signTransfer(wallet: Wallet, boc: String)
}

public protocol ExternalWalletController {
    func processUrl(_ url: URL) throws -> ExternalWalletControllerAction
    func reset()
    func exportWallet(_ wallet: Wallet)
}

public final class ExternalWalletControllerImplementation: ExternalWalletController {
    enum State {
        case idle
        case signing
    }
    
    private var state: State = .idle
    
    private let walletProvider: WalletProvider
    private let urlParser: ExternalWalletURLParser
    
    init(walletProvider: WalletProvider,
         urlParser: ExternalWalletURLParser) {
        self.walletProvider = walletProvider
        self.urlParser = urlParser
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
    
    public func exportWallet(_ wallet: Wallet) {}
}
