//
//  AccountTokensBalanceService.swift
//  
//
//  Created by Grigory on 1.7.23..
//

import Foundation
import TonSwift
import TonAPI
import BigInt

protocol AccountTokensBalanceService {
    func loadTokensBalance(address: Address) async throws -> [TokenBalance]
}

final class AccountTokensBalanceServiceImplementation: AccountTokensBalanceService {
    
    private let api: API
    
    init(api: API) {
        self.api = api
    }
    
    func loadTokensBalance(address: Address) async throws -> [TokenBalance] {
        let request = AccountJettonsRequest(accountId: address.toRaw())
        let response = try await api.send(request: request)
                
        let balances = response.entity.balances.compactMap { jetton in
            do {
                let tokenAddress = try Address.parse(jetton.jetton.address)
                let quantity = BigInt(stringLiteral: jetton.balance)
                let walletAddress = try Address.parse(jetton.walletAddress.address)
                let tokenInfo = TokenInfo(address: tokenAddress,
                                          fractionDigits: jetton.jetton.decimals,
                                          name: jetton.jetton.name,
                                          symbol: jetton.jetton.symbol,
                                          imageURL: URL(string: jetton.jetton.image))
                let tokenAmount = TokenAmount(tokenInfo: tokenInfo,
                                              quantity: quantity)
                let tokenBalance = TokenBalance(walletAddress: walletAddress, amount: tokenAmount)
                return tokenBalance
            } catch {
                return nil
            }
        }
        return balances
    }
}
