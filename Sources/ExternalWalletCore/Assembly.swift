//
//  Assembly.swift
//
//
//  Created by Grigory Serebryanyy on 23.11.2023.
//

import Foundation
import WalletCoreCore

public final class Assembly {
    private let walletCoreCoreAssembly: WalletCoreCore.Assembly
    
    public init(dependencies: Dependencies) {
        walletCoreCoreAssembly = .init(dependencies: dependencies)
    }
    
    public lazy var externalWalletController: ExternalWalletController = {
        ExternalWalletControllerImplementation(
            walletProvider: walletCoreCoreAssembly.walletProvider,
            urlParser: urlParser,
            urlBuilder: urlBuilder)
    }()
    
    public var transferSignController: TransferSignController {
        TransferSignControllerImplementation(walletProvider: walletCoreCoreAssembly.walletProvider)
    }
}

private extension Assembly {
    var urlParser: ExternalWalletURLParser {
        ExternalWalletURLParserImplementation()
    }
    
    var urlBuilder: ExternalWalletURLBuilder {
        ExternalWalletURLBuilderImplementation()
    }
}
