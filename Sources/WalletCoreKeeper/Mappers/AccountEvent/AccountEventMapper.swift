//
//  AccountEventMapper.swift
//  
//
//  Created by Grigory on 4.8.23..
//

import Foundation
import BigInt
import WalletCoreCore

struct AccountEventMapper {
    private let dateFormatter: DateFormatter
    private let amountFormatter: AmountFormatter
    private let intAmountFormatter: IntAmountFormatter
    private let amountMapper: AccountEventActionAmountMapper
    
    init(dateFormatter: DateFormatter,
         amountFormatter: AmountFormatter,
         intAmountFormatter: IntAmountFormatter,
         amountMapper: AccountEventActionAmountMapper) {
        self.dateFormatter = dateFormatter
        self.amountFormatter = amountFormatter
        self.intAmountFormatter = intAmountFormatter
        self.amountMapper = amountMapper
    }
    
    func mapActivityEvent(_ event: AccountEvent,
                          collectibles: Collectibles,
                          accountEventRightTopDescriptionProvider: AccountEventRightTopDescriptionProvider) -> ActivityEventViewModel {
        var accountEventRightTopDescriptionProvider = accountEventRightTopDescriptionProvider
        let actionViewModels = event.actions.compactMap { action in
            let rightTopDescription = accountEventRightTopDescriptionProvider.rightTopDescription(
                accountEvent: event,
                action: action
            )
            return mapAction(
                action,
                activityEvent: event,
                rightTopDescription: rightTopDescription,
                collectibles: collectibles)
        }
        return ActivityEventViewModel(actions: actionViewModels)
    }
    
    func mapEventsSectionDate(_ date: Date) -> String? {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .month) {
            dateFormatter.dateFormat = "d MMMM"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            dateFormatter.dateFormat = "LLLL"
        } else {
            dateFormatter.dateFormat = "LLLL y"
        }
        return dateFormatter.string(from: date).capitalized
    }
}

private extension AccountEventMapper {
    func mapAction(_ action: Action,
                   activityEvent: AccountEvent,
                   rightTopDescription: String?,
                   collectibles: Collectibles) -> ActivityEventViewModel.ActionViewModel? {

        switch action.type {
        case .tonTransfer(let tonTransfer):
            return mapTonTransferAction(tonTransfer,
                                        activityEvent: activityEvent,
                                        preview: action.preview,
                                        rightTopDescription: rightTopDescription,
                                        status: action.status.rawValue)
        case .jettonTransfer(let jettonTransfer):
            return mapJettonTransferAction(jettonTransfer,
                                           activityEvent: activityEvent,
                                           preview: action.preview,
                                           rightTopDescription: rightTopDescription,
                                           status: action.status.rawValue)
        case .jettonMint(let jettonMint):
            return mapJettonMintAction(jettonMint,
                                       activityEvent: activityEvent,
                                       preview: action.preview,
                                       rightTopDescription: rightTopDescription,
                                       status: action.status.rawValue)
        case .jettonBurn(let jettonBurn):
            return mapJettonBurnAction(jettonBurn,
                                       activityEvent: activityEvent,
                                       preview: action.preview,
                                       rightTopDescription: rightTopDescription,
                                       status: action.status.rawValue)
        case .auctionBid(let auctionBid):
            return mapAuctionBidAction(auctionBid,
                                       activityEvent: activityEvent,
                                       preview: action.preview,
                                       rightTopDescription: rightTopDescription,
                                       status: action.status.rawValue)
        case .nftPurchase(let nftPurchase):
            return mapNFTPurchaseAction(nftPurchase,
                                        activityEvent: activityEvent,
                                        preview: action.preview,
                                        rightTopDescription: rightTopDescription,
                                        status: action.status.rawValue)
        case .contractDeploy(let contractDeploy):
            return mapContractDeployAction(contractDeploy,
                                           activityEvent: activityEvent,
                                           preview: action.preview,
                                           rightTopDescription: rightTopDescription,
                                           status: action.status.rawValue)
        case .smartContractExec(let smartContractExec):
            return mapSmartContractExecAction(smartContractExec,
                                              activityEvent: activityEvent,
                                              preview: action.preview,
                                              rightTopDescription: rightTopDescription,
                                              status: action.status.rawValue)
        case .nftItemTransfer(let nftItemTransfer):
            return mapItemTransferAction(nftItemTransfer,
                                         activityEvent: activityEvent,
                                         preview: action.preview,
                                         rightTopDescription: rightTopDescription,
                                         status: action.status.rawValue,
                                         collectibles: collectibles)
        case .depositStake(let depositStake):
            return mapDepositStakeAction(depositStake,
                                         activityEvent: activityEvent,
                                         preview: action.preview,
                                         rightTopDescription: rightTopDescription,
                                         status: action.status.rawValue)
        case .withdrawStake(let withdrawStake):
            return mapWithdrawStakeAction(withdrawStake,
                                          activityEvent: activityEvent,
                                          preview: action.preview,
                                          rightTopDescription: rightTopDescription,
                                          status: action.status.rawValue)
        case .withdrawStakeRequest(let withdrawStakeRequest):
            return mapWithdrawStakeRequestAction(withdrawStakeRequest,
                                                 activityEvent: activityEvent,
                                                 preview: action.preview,
                                                 rightTopDescription: rightTopDescription,
                                                 status: action.status.rawValue)
        case .jettonSwap(let jettonSwap):
            return mapJettonSwapAction(jettonSwap,
                                       activityEvent: activityEvent,
                                       preview: action.preview,
                                       rightTopDescription: rightTopDescription,
                                       status: action.status.rawValue)
        case .domainRenew(let domainRenew):
            return mapDomainRenewAction(
                domainRenew,
                activityEvent: activityEvent,
                preview: action.preview,
                rightTopDescription: rightTopDescription,
                status: action.status.rawValue)
        case .unknown:
            return mapUnknownAction(rightTopDescription: rightTopDescription)
        default: return nil
        }
    }
    
    func mapTonTransferAction(_ action: Action.TonTransfer,
                              activityEvent: AccountEvent,
                              preview: Action.SimplePreview,
                              rightTopDescription: String?,
                              status: String?) -> ActivityEventViewModel.ActionViewModel {
        let tonInfo = TonInfo()
        let eventType: ActivityEventViewModel.ActionViewModel.ActionType
        let leftTopDescription: String
        let amountType: AccountEventActionAmountMapperActionType
        
        if activityEvent.isScam {
            amountType = .income
            eventType = .spam
            leftTopDescription = action.sender.value
        } else if action.recipient == activityEvent.account {
            amountType = .income
            eventType = .receieved
            leftTopDescription = action.sender.value
        } else {
            amountType = .outcome
            eventType = .sent
            leftTopDescription = action.recipient.value
        }
        
        let amount = amountMapper
            .mapAmount(
                amount: BigInt(integerLiteral: action.amount),
                fractionDigits: tonInfo.fractionDigits,
                maximumFractionDigits: 2,
                type: amountType,
                currency: .TON)
        return ActivityEventViewModel.ActionViewModel(eventType: eventType,
                                                      amount: amount,
                                                      subamount: nil,
                                                      leftTopDescription: leftTopDescription,
                                                      leftBottomDescription: nil,
                                                      rightTopDescription: rightTopDescription,
                                                      status: status,
                                                      comment: action.comment,
                                                      collectible: nil)
    }
    
    func mapJettonTransferAction(_ action: Action.JettonTransfer,
                                 activityEvent: AccountEvent,
                                 preview: Action.SimplePreview,
                                 rightTopDescription: String?,
                                 status: String?) -> ActivityEventViewModel.ActionViewModel {
        let eventType: ActivityEventViewModel.ActionViewModel.ActionType
        let leftTopDescription: String?
        let amountType: AccountEventActionAmountMapperActionType
        if activityEvent.isScam {
            eventType = .spam
            leftTopDescription = action.sender?.value ?? nil
            amountType = .income
        } else if action.recipient == activityEvent.account {
            eventType = .receieved
            leftTopDescription = action.sender?.value ?? nil
            amountType = .income
        } else {
            eventType = .sent
            leftTopDescription = action.recipient?.value ?? nil
            amountType = .outcome
        }
        
        let amount = amountMapper
            .mapAmount(
                amount: action.amount,
                fractionDigits: action.tokenInfo.fractionDigits,
                maximumFractionDigits: 2,
                type: amountType,
                symbol: action.tokenInfo.symbol)
        
        return ActivityEventViewModel.ActionViewModel(eventType: eventType,
                                                      amount: amount,
                                                      subamount: nil,
                                                      leftTopDescription: leftTopDescription,
                                                      leftBottomDescription: nil,
                                                      rightTopDescription: rightTopDescription,
                                                      status: status,
                                                      comment: action.comment,
                                                      collectible: nil)
    }
    
    func mapJettonMintAction(_ action: Action.JettonMint,
                             activityEvent: AccountEvent,
                             preview: Action.SimplePreview,
                             rightTopDescription: String?,
                             status: String?) -> ActivityEventViewModel.ActionViewModel {
        let amount = amountMapper.mapAmount(
            amount: action.amount,
            fractionDigits: action.tokenInfo.fractionDigits,
            maximumFractionDigits: 2,
            type: .income,
            symbol: action.tokenInfo.symbol)
        
        return ActivityEventViewModel.ActionViewModel(eventType: .mint,
                                                      amount: amount,
                                                      subamount: nil,
                                                      leftTopDescription: action.tokenInfo.name,
                                                      leftBottomDescription: nil,
                                                      rightTopDescription: rightTopDescription,
                                                      status: status,
                                                      comment: nil,
                                                      collectible: nil)
    }
    
    func mapJettonBurnAction(_ action: Action.JettonBurn,
                             activityEvent: AccountEvent,
                             preview: Action.SimplePreview,
                             rightTopDescription: String?,
                             status: String?) -> ActivityEventViewModel.ActionViewModel {
        let amount = amountMapper.mapAmount(
            amount: action.amount,
            fractionDigits: action.tokenInfo.fractionDigits,
            maximumFractionDigits: 2,
            type: .outcome,
            symbol: action.tokenInfo.symbol)
        
        return ActivityEventViewModel.ActionViewModel(eventType: .burn,
                                                      amount: amount,
                                                      subamount: nil,
                                                      leftTopDescription: action.tokenInfo.name,
                                                      leftBottomDescription: nil,
                                                      rightTopDescription: rightTopDescription,
                                                      status: status,
                                                      comment: nil,
                                                      collectible: nil)
    }
    
    func mapDepositStakeAction(_ action: Action.DepositStake,
                               activityEvent: AccountEvent,
                               preview: Action.SimplePreview,
                               rightTopDescription: String?,
                               status: String?) -> ActivityEventViewModel.ActionViewModel {
        let tonInfo = TonInfo()
        let amount = amountMapper.mapAmount(
            amount: BigInt(integerLiteral: action.amount),
            fractionDigits: tonInfo.fractionDigits,
            maximumFractionDigits: tonInfo.fractionDigits,
            type: .outcome,
            currency: .TON)
        
        return ActivityEventViewModel.ActionViewModel(
            eventType: .depositStake,
            amount: amount,
            subamount: nil,
            leftTopDescription: action.pool.name,
            leftBottomDescription: nil,
            rightTopDescription: rightTopDescription,
            status: status,
            comment: nil,
            collectible: nil
        )
    }
    
    func mapWithdrawStakeAction(_ action: Action.WithdrawStake,
                                activityEvent: AccountEvent,
                                preview: Action.SimplePreview,
                                rightTopDescription: String?,
                                status: String?) -> ActivityEventViewModel.ActionViewModel {
        let tonInfo = TonInfo()
        let amount = amountMapper.mapAmount(
            amount: BigInt(integerLiteral: action.amount),
            fractionDigits: tonInfo.fractionDigits,
            maximumFractionDigits: 2,
            type: .income,
            currency: .TON)
        
        return ActivityEventViewModel.ActionViewModel(
            eventType: .withdrawStake,
            amount: amount,
            subamount: nil,
            leftTopDescription: action.pool.name,
            leftBottomDescription: nil,
            rightTopDescription: rightTopDescription,
            status: status,
            comment: nil,
            collectible: nil
        )
    }
    
    func mapWithdrawStakeRequestAction(_ action: Action.WithdrawStakeRequest,
                                       activityEvent: AccountEvent,
                                       preview: Action.SimplePreview,
                                       rightTopDescription: String?,
                                       status: String?) -> ActivityEventViewModel.ActionViewModel {
        let tonInfo = TonInfo()
        let amount = amountMapper.mapAmount(
            amount: BigInt(integerLiteral: action.amount ?? 0),
            fractionDigits: tonInfo.fractionDigits,
            maximumFractionDigits: 2,
            type: .none,
            currency: .TON)
        
        return ActivityEventViewModel.ActionViewModel(eventType: .withdrawStakeRequest,
                                                      amount: amount,
                                                      subamount: nil,
                                                      leftTopDescription: action.pool.name,
                                                      leftBottomDescription: nil,
                                                      rightTopDescription: rightTopDescription,
                                                      status: status,
                                                      comment: nil,
                                                      collectible: nil)
    }
    
    func mapAuctionBidAction(_ action: Action.AuctionBid,
                             activityEvent: AccountEvent,
                             preview: Action.SimplePreview,
                             rightTopDescription: String?,
                             status: String?) -> ActivityEventViewModel.ActionViewModel {
        var collectible: ActivityEventViewModel.ActionViewModel.CollectibleViewModel?
        if let actionCollectible = action.collectible {
            collectible = ActivityEventViewModel.ActionViewModel.CollectibleViewModel(
                name: actionCollectible.name,
                collectionName: actionCollectible.collection?.name,
                image: .url(actionCollectible.preview.size500))
        }
        
        return ActivityEventViewModel.ActionViewModel(eventType: .bid,
                                                      amount: preview.value,
                                                      subamount: nil,
                                                      leftTopDescription: action.bidder.value,
                                                      leftBottomDescription: nil,
                                                      rightTopDescription: rightTopDescription,
                                                      status: status,
                                                      comment: nil,
                                                      collectible: collectible)
    }
    
    func mapNFTPurchaseAction(_ action: Action.NFTPurchase,
                              activityEvent: AccountEvent,
                              preview: Action.SimplePreview,
                              rightTopDescription: String?,
                              status: String?) -> ActivityEventViewModel.ActionViewModel {
        
        let collectibleViewModel = ActivityEventViewModel.ActionViewModel.CollectibleViewModel(
            name: action.collectible.name,
            collectionName: action.collectible.collection?.name,
            image: .url(action.collectible.preview.size500)
        )
        let tonInfo = TonInfo()
        let amount = amountMapper
            .mapAmount(
                amount: action.price,
                fractionDigits: tonInfo.fractionDigits,
                maximumFractionDigits: 2,
                type: action.buyer == activityEvent.account ? .outcome : .income,
                currency: .TON
            )
        
        return ActivityEventViewModel.ActionViewModel(
            eventType: .nftPurchase,
            amount: amount,
            subamount: nil,
            leftTopDescription: action.seller.value,
            leftBottomDescription: nil,
            rightTopDescription: rightTopDescription,
            status: status,
            comment: nil,
            collectible: collectibleViewModel
        )
    }
    
    func mapContractDeployAction(_ action: Action.ContractDeploy,
                                 activityEvent: AccountEvent,
                                 preview: Action.SimplePreview,
                                 rightTopDescription: String?,
                                 status: String?) -> ActivityEventViewModel.ActionViewModel {
        return ActivityEventViewModel.ActionViewModel(
            eventType: .walletInitialized,
            amount: "-",
            subamount: nil,
            leftTopDescription: action.address.toShortString(bounceable: true),
            leftBottomDescription: nil,
            rightTopDescription: rightTopDescription,
            status: status,
            comment: nil,
            collectible: nil
        )
    }
    
    func mapSmartContractExecAction(_ action: Action.SmartContractExec,
                                    activityEvent: AccountEvent,
                                    preview: Action.SimplePreview,
                                    rightTopDescription: String?,
                                    status: String?) -> ActivityEventViewModel.ActionViewModel {
        let tonInfo = TonInfo()
        let amount = amountMapper
            .mapAmount(
                amount: BigInt(integerLiteral: action.tonAttached),
                fractionDigits: tonInfo.fractionDigits,
                maximumFractionDigits: 2,
                type: action.executor == activityEvent.account ? .outcome : .income,
                currency: .TON
            )
        
        return ActivityEventViewModel.ActionViewModel(eventType: .contractExec,
                                                      amount: amount,
                                                      subamount: nil,
                                                      leftTopDescription: action.contract.value,
                                                      leftBottomDescription: nil,
                                                      rightTopDescription: rightTopDescription,
                                                      status: status,
                                                      comment: nil,
                                                      collectible: nil)
    }
    
    func mapItemTransferAction(_ action: Action.NFTItemTransfer,
                               activityEvent: AccountEvent,
                               preview: Action.SimplePreview,
                               rightTopDescription: String?,
                               status: String?,
                               collectibles: Collectibles) -> ActivityEventViewModel.ActionViewModel {
        let eventType: ActivityEventViewModel.ActionViewModel.ActionType
        let leftTopDescription: String?
        
        if activityEvent.isScam {
            eventType = .spam
            leftTopDescription = action.sender?.value
        } else if action.sender == activityEvent.account {
            eventType = .sent
            leftTopDescription = action.recipient?.value
        } else {
            eventType = .receieved
            leftTopDescription = action.sender?.value
        }
        
        var collectible: ActivityEventViewModel.ActionViewModel.CollectibleViewModel?
        if let actionCollectible = collectibles.collectibles[action.nftAddress] {
            collectible = .init(name: actionCollectible.name,
                                collectionName: actionCollectible.collection?.name,
                                image: .url(actionCollectible.preview.size500))
        }
        
        return ActivityEventViewModel.ActionViewModel(eventType: eventType,
                                                      amount: "NFT",
                                                      subamount: nil,
                                                      leftTopDescription: leftTopDescription,
                                                      leftBottomDescription: nil,
                                                      rightTopDescription: rightTopDescription,
                                                      status: status,
                                                      comment: action.comment,
                                                      collectible: collectible)
    }
    
    func mapJettonSwapAction(_ action: Action.JettonSwap,
                             activityEvent: AccountEvent,
                             preview: Action.SimplePreview,
                             rightTopDescription: String?,
                             status: String?) -> ActivityEventViewModel.ActionViewModel {
        
        let tonInfo = TonInfo()
        let outAmount: String? = {
            let amount: BigInt
            let fractionDigits: Int
            let maximumFractionDigits: Int
            let symbol: String?
            if let tonOut = action.tonOut {
                amount = BigInt(integerLiteral: tonOut)
                fractionDigits = tonInfo.fractionDigits
                maximumFractionDigits = 2
                symbol = tonInfo.symbol
            } else if let tokenInfoOut = action.tokenInfoOut {
                amount = action.amountOut
                fractionDigits = tokenInfoOut.fractionDigits
                maximumFractionDigits = 2
                symbol = tokenInfoOut.symbol
            } else {
                return nil
            }

            return amountMapper
                .mapAmount(
                    amount: amount,
                    fractionDigits: fractionDigits,
                    maximumFractionDigits: maximumFractionDigits,
                    type: .income,
                    symbol: symbol
                )
        }()
        
        let inAmount: String? = {
            let amount: BigInt
            let fractionDigits: Int
            let maximumFractionDigits: Int
            let symbol: String?
            if let tonIn = action.tonIn {
                amount = BigInt(integerLiteral: tonIn)
                fractionDigits = tonInfo.fractionDigits
                maximumFractionDigits = 2
                symbol = tonInfo.symbol
            } else if let tokenInfoIn = action.tokenInfoIn {
                amount = action.amountIn
                fractionDigits = tokenInfoIn.fractionDigits
                maximumFractionDigits = 2
                symbol = tokenInfoIn.symbol
            } else {
                return nil
            }
            return amountMapper
                .mapAmount(
                    amount: amount,
                    fractionDigits: fractionDigits,
                    maximumFractionDigits: maximumFractionDigits,
                    type: .outcome,
                    symbol: symbol
                )
        }()
        
        return ActivityEventViewModel.ActionViewModel(
            eventType: .jettonSwap,
            amount: outAmount,
            subamount: inAmount,
            leftTopDescription: action.user.value,
            leftBottomDescription: nil,
            rightTopDescription: rightTopDescription,
            status: status,
            comment: nil,
            collectible: nil
        )
    }
    
    func mapDomainRenewAction(_ action: Action.DomainRenew,
                             activityEvent: AccountEvent,
                             preview: Action.SimplePreview,
                             rightTopDescription: String?,
                             status: String?) -> ActivityEventViewModel.ActionViewModel {

        return ActivityEventViewModel.ActionViewModel(
            eventType: .domainRenew,
            amount: action.domain,
            subamount: nil,
            leftTopDescription: action.renewer.value,
            leftBottomDescription: nil,
            rightTopDescription: rightTopDescription,
            status: status,
            comment: nil,
            description: preview.description,
            collectible: nil
        )
    }
    
    func mapUnknownAction(rightTopDescription: String?) -> ActivityEventViewModel.ActionViewModel {
        return ActivityEventViewModel.ActionViewModel(
            eventType: .unknown,
            amount: String.Symbol.minus,
            subamount: nil,
            leftTopDescription: "Something happened but we couldn't recognize",
            leftBottomDescription: nil,
            rightTopDescription: rightTopDescription,
            status: nil,
            comment: nil,
            collectible: nil
        )
    }
}

private extension WalletAccount {
    var value: String {
        if let name = name { return name }
        return address.toShortString(bounceable: !isWallet)
    }
}
