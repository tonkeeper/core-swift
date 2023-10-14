//
//  FiatMethodsController.swift
//
//
//  Created by Grigory on 14.10.23..
//

import Foundation

public final class FiatMethodsController {
    private let fiatMethodsService: FiatMethodsService
    
    init(fiatMethodsService: FiatMethodsService) {
        self.fiatMethodsService = fiatMethodsService
    }
    
    public func getFiatMethods() async throws -> [[FiatMethodViewModel]] {
        let fiatMethods = try await fiatMethodsService.getFiatMethods()
        return mapFiatMethods(fiatMethods: fiatMethods)
    }
    
    public func loadFiatMethods() async throws -> [[FiatMethodViewModel]] {
        let fiatMethods = try await fiatMethodsService.loadFiatMethods()
        return mapFiatMethods(fiatMethods: fiatMethods)
    }
}

private extension FiatMethodsController {
    func mapFiatMethods(fiatMethods: FiatMethods) -> [[FiatMethodViewModel]] {
        let sections = fiatMethods.categories.map { category in
            category.items.compactMap { item -> FiatMethodViewModel? in
                guard fiatMethods.defaultLayout.methods.contains(item.id) else { return nil }
                return FiatMethodViewModel(
                    title: item.title,
                    description: item.description,
                    token: item.badge,
                    iconURL: item.iconURL
                )
            }
        }
        return sections
    }
}
