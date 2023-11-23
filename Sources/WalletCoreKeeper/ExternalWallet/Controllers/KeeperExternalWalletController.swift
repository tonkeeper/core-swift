//
//  KeeperExternalWalletController.swift
//
//
//  Created by Grigory Serebryanyy on 23.11.2023.
//

import Foundation
import TonSwift

public enum KeeperExternalWalletControllerError: Swift.Error {
    case incorrectUrl
}

public protocol KeeperExternalWalletControllerImportObserver: AnyObject {
    func controller(_ controller: KeeperExternalWalletController,
                    didImportWallet with: TonSwift.PublicKey)
}

public protocol KeeperExternalWalletController {
    func processUrl(_ url: URL) throws
    
    func addObserver(_ observer: KeeperExternalWalletControllerImportObserver)
    func removeObserver(_ observer: KeeperExternalWalletControllerImportObserver)
}

final class KeeperExternalWalletControllerImplementation: KeeperExternalWalletController {
    
    private let urlParser: KeeperExternalWalletURLParser
    
    init(urlParser: KeeperExternalWalletURLParser) {
        self.urlParser = urlParser
    }
    
    func processUrl(_ url: URL) throws {
        let action: KeeperExternalWalletAction
        do {
            action = try urlParser.parseUrl(url)
        } catch {
            throw KeeperExternalWalletControllerError.incorrectUrl
        }
        
        switch action {
        case .importWallet(let publicKey):
            notifyObserversWalletImported(publicKey: publicKey)
        }
    }
    
    // MARK: - Observering
    
    struct KeeperExternalWalletControllerImportObserverWrapper {
        weak var observer: KeeperExternalWalletControllerImportObserver?
    }
    
    private var observers = [KeeperExternalWalletControllerImportObserverWrapper]()
    
    public func addObserver(_ observer: KeeperExternalWalletControllerImportObserver) {
        removeNilObservers()
        observers = observers + CollectionOfOne(KeeperExternalWalletControllerImportObserverWrapper(observer: observer))
    }
    
    public func removeObserver(_ observer: KeeperExternalWalletControllerImportObserver) {
        removeNilObservers()
        observers = observers.filter { $0.observer !== observer }
    }
}

private extension KeeperExternalWalletControllerImplementation {
    func notifyObserversWalletImported(publicKey: TonSwift.PublicKey) {
        observers.forEach { $0.observer?.controller(
            self,
            didImportWallet: publicKey
        )}
    }
    
    func removeNilObservers() {
        observers = observers.filter { $0.observer != nil }
    }
}
