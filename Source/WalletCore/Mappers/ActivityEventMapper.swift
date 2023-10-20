//
//  ActivityEventMapper.swift
//  
//
//  Created by Grigory on 4.8.23..
//

import Foundation
import BigInt

struct ActivityEventMapper {
    private let dateFormatter: DateFormatter
    private let amountFormatter: AmountFormatter
    private let intAmountFormatter: IntAmountFormatter
    
    init(dateFormatter: DateFormatter,
         amountFormatter: AmountFormatter,
         intAmountFormatter: IntAmountFormatter) {
        self.dateFormatter = dateFormatter
        self.amountFormatter = amountFormatter
        self.intAmountFormatter = intAmountFormatter
    }
    
    func mapActivityEvent(_ event: ActivityEvent, dateFormat: String, collectibles: Collectibles) -> ActivityEventViewModel {
        let eventDate = Date(timeIntervalSince1970: event.timestamp)
        dateFormatter.dateFormat = dateFormat
        let date = dateFormatter.string(from: eventDate)
        let actionViewModels = event.actions.compactMap { action in
            mapAction(action, activityEvent: event, date: date, collectibles: collectibles)
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

private extension ActivityEventMapper {
    func mapAction(_ action: Action, activityEvent: ActivityEvent, date: String, collectibles: Collectibles) -> ActivityEventViewModel.ActionViewModel? {

        switch action.type {
        case .tonTransfer(let tonTransfer):
            return mapTonTransferAction(tonTransfer,
                                        activityEvent: activityEvent,
                                        preview: action.preview,
                                        date: date,
                                        status: action.status.rawValue)
        case .jettonTransfer(let jettonTransfer):
            return mapJettonTransferAction(jettonTransfer,
                                           activityEvent: activityEvent,
                                           preview: action.preview,
                                           date: date,
                                           status: action.status.rawValue)
        case .jettonMint(let jettonMint):
            return mapJettonMintAction(jettonMint,
                                       activityEvent: activityEvent,
                                       preview:action.preview,
                                       date: date,
                                       status: action.status.rawValue)
        case .auctionBid(let auctionBid):
            return mapAuctionBidAction(auctionBid,
                                       activityEvent: activityEvent,
                                       preview: action.preview,
                                       date: date,
                                       status: action.status.rawValue)
        case .nftPurchase(let nftPurchase):
            return mapNFTPurchaseAction(nftPurchase,
                                        activityEvent: activityEvent,
                                        preview: action.preview,
                                        date: date,
                                        status: action.status.rawValue)
        case .contractDeploy(let contractDeploy):
            return mapContractDeployAction(contractDeploy,
                                           activityEvent: activityEvent,
                                           preview: action.preview,
                                           date: date,
                                           status: action.status.rawValue)
        case .smartContractExec(let smartContractExec):
            return mapSmartContractExecAction(smartContractExec,
                                              activityEvent: activityEvent,
                                              preview: action.preview,
                                              date: date,
                                              status: action.status.rawValue)
        case .nftItemTransfer(let nftItemTransfer):
            return mapItemTransferAction(nftItemTransfer,
                                         activityEvent: activityEvent,
                                         preview: action.preview,
                                         date: date,
                                         status: action.status.rawValue,
                                         collectibles: collectibles)
        case .depositStake(let depositStake):
            return mapDepositStakeAction(depositStake,
                                         activityEvent: activityEvent,
                                         preview: action.preview,
                                         date: date,
                                         status: action.status.rawValue)
        case .withdrawStake(let withdrawStake):
            return mapWithdrawStakeAction(withdrawStake,
                                          activityEvent: activityEvent,
                                          preview: action.preview,
                                          date: date,
                                          status: action.status.rawValue)
        case .jettonSwap(let jettonSwap):
            return mapJettonSwapAction(jettonSwap,
                                       activityEvent: activityEvent,
                                       preview: action.preview,
                                       date: date,
                                       status: action.status.rawValue)
        case .subscribe(let subscribe):
            return nil
        case .unsubscribe(let unsubscribe):
            return nil
        }
    }
    
    func mapTonTransferAction(_ action: Action.TonTransfer,
                              activityEvent: ActivityEvent,
                              preview: Action.SimplePreview,
                              date: String,
                              status: String?) -> ActivityEventViewModel.ActionViewModel {
        let tonInfo = TonInfo()
        let eventType: ActivityEventViewModel.ActionViewModel.ActionType
        let leftTopDescription: String
        let sign: String
        if activityEvent.isScam {
            eventType = .spam
            leftTopDescription = action.sender.value
            sign = "+"
        } else if action.recipient == activityEvent.account {
            if action.recipient == action.sender {
                eventType = .sentAndReceieved
                sign = "-"
            } else {
                eventType = .receieved
                sign = "+"
            }
            
            leftTopDescription = action.sender.value
        } else {
            eventType = .sent
            leftTopDescription = action.recipient.value
            sign = "-"
        }
        
        let amount = amountFormatter.formatAmount(
            BigInt(integerLiteral: action.amount),
            fractionDigits: tonInfo.fractionDigits,
            maximumFractionDigits: tonInfo.fractionDigits
        )
        let subamount: String? = {
            guard eventType == .sentAndReceieved else { return nil }
            return "+\(amount) \(tonInfo.symbol)"
        }()
        
        return ActivityEventViewModel.ActionViewModel(eventType: eventType,
                                                      amount: "\(sign)\(amount) \(tonInfo.symbol)",
                                                      subamount: subamount,
                                                      leftTopDescription: leftTopDescription,
                                                      leftBottomDescription: nil,
                                                      date: date,
                                                      rightTopDesription: date,
                                                      status: status,
                                                      comment: action.comment,
                                                      collectible: nil)
    }
    
    func mapJettonTransferAction(_ action: Action.JettonTransfer,
                                 activityEvent: ActivityEvent,
                                 preview: Action.SimplePreview,
                                 date: String,
                                 status: String?) -> ActivityEventViewModel.ActionViewModel {
        let eventType: ActivityEventViewModel.ActionViewModel.ActionType
        let leftTopDescription: String?
        let sign: String
        if activityEvent.isScam {
            eventType = .spam
            leftTopDescription = action.sender?.value ?? nil
            sign = " "
        } else if action.recipient == activityEvent.account {
            eventType = .receieved
            leftTopDescription = action.sender?.value ?? nil
            sign = "+"
        } else {
            eventType = .sent
            leftTopDescription = action.recipient?.value ?? nil
            sign = "-"
        }
        
        var amount = sign + amountFormatter.formatAmount(
            action.amount,
            fractionDigits: action.tokenInfo.fractionDigits,
            maximumFractionDigits: action.tokenInfo.fractionDigits)
        if let symbol = action.tokenInfo.symbol {
            amount += " \(symbol)"
        }
        
        return ActivityEventViewModel.ActionViewModel(eventType: eventType,
                                                      amount: amount,
                                                      subamount: nil,
                                                      leftTopDescription: leftTopDescription,
                                                      leftBottomDescription: nil,
                                                      date: date,
                                                      rightTopDesription: date,
                                                      status: status,
                                                      comment: action.comment,
                                                      collectible: nil)
    }
    
    func mapJettonMintAction(_ action: Action.JettonMint,
                             activityEvent: ActivityEvent,
                             preview: Action.SimplePreview,
                             date: String,
                             status: String?) -> ActivityEventViewModel.ActionViewModel {
        let eventType = ActivityEventViewModel.ActionViewModel.ActionType.mint
        let leftTopDescription = action.tokenInfo.name
        
        var amount = "+" + amountFormatter.formatAmount(
            action.amount,
            fractionDigits: action.tokenInfo.fractionDigits,
            maximumFractionDigits: action.tokenInfo.fractionDigits)
        if let symbol = action.tokenInfo.symbol {
            amount += " \(symbol)"
        }
        
        return ActivityEventViewModel.ActionViewModel(eventType: eventType,
                                                      amount: amount,
                                                      subamount: nil,
                                                      leftTopDescription: leftTopDescription,
                                                      leftBottomDescription: nil,
                                                      date: date,
                                                      rightTopDesription: date,
                                                      status: status,
                                                      comment: nil,
                                                      collectible: nil)
    }
    
    func mapDepositStakeAction(_ action: Action.DepositStake,
                               activityEvent: ActivityEvent,
                               preview: Action.SimplePreview,
                               date: String,
                               status: String?) -> ActivityEventViewModel.ActionViewModel {
        let leftTopDescription = action.pool.name
        
        let tonInfo = TonInfo()
        let amount = "-" + amountFormatter.formatAmount(
            BigInt(integerLiteral: action.amount),
            fractionDigits: tonInfo.fractionDigits,
            maximumFractionDigits: tonInfo.fractionDigits
        ) + " \(tonInfo.symbol)"
        
        return ActivityEventViewModel.ActionViewModel(eventType: .depositStake,
                                                      amount: amount,
                                                      subamount: nil,
                                                      leftTopDescription: leftTopDescription,
                                                      leftBottomDescription: nil,
                                                      date: date,
                                                      rightTopDesription: date,
                                                      status: status,
                                                      comment: nil,
                                                      collectible: nil)
    }
    
    func mapWithdrawStakeAction(_ action: Action.WithdrawStake,
                                activityEvent: ActivityEvent,
                                preview: Action.SimplePreview,
                                date: String,
                                status: String?) -> ActivityEventViewModel.ActionViewModel {
        let leftTopDescription = action.pool.name
        
        let tonInfo = TonInfo()
        let amount = amountFormatter.formatAmount(
            BigInt(integerLiteral: action.amount),
            fractionDigits: tonInfo.fractionDigits,
            maximumFractionDigits: tonInfo.fractionDigits
        )
        
        return ActivityEventViewModel.ActionViewModel(eventType: .withdrawStake,
                                                      amount: amount,
                                                      subamount: nil,
                                                      leftTopDescription: leftTopDescription,
                                                      leftBottomDescription: nil,
                                                      date: date,
                                                      rightTopDesription: date,
                                                      status: status,
                                                      comment: nil,
                                                      collectible: nil)
    }
    
    func mapAuctionBidAction(_ action: Action.AuctionBid,
                             activityEvent: ActivityEvent,
                             preview: Action.SimplePreview,
                             date: String,
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
                                                      date: date,
                                                      rightTopDesription: date,
                                                      status: status,
                                                      comment: nil,
                                                      collectible: collectible)
    }
    
    func mapNFTPurchaseAction(_ action: Action.NFTPurchase,
                              activityEvent: ActivityEvent,
                              preview: Action.SimplePreview,
                              date: String,
                              status: String?) -> ActivityEventViewModel.ActionViewModel {
        
        let collectibleViewModel = ActivityEventViewModel.ActionViewModel.CollectibleViewModel(
            name: action.collectible.name,
            collectionName: action.collectible.collection?.name,
            image: .url(action.collectible.preview.size500)
        )
        
        let sign = action.buyer == activityEvent.account ? "-" : "+"
        
        let tonInfo = TonInfo()
        var amount = amountFormatter.formatAmount(
            action.price,
            fractionDigits: tonInfo.fractionDigits,
            maximumFractionDigits: tonInfo.fractionDigits
        )
        amount = "\(sign) \(amount) \(tonInfo.symbol)"
        
        return ActivityEventViewModel.ActionViewModel(
            eventType: .nftPurchase,
            amount: amount,
            subamount: nil,
            leftTopDescription: action.seller.value,
            leftBottomDescription: nil,
            date: date,
            rightTopDesription: date,
            status: status,
            comment: nil,
            collectible: collectibleViewModel
        )
    }
    
    func mapContractDeployAction(_ action: Action.ContractDeploy,
                                 activityEvent: ActivityEvent,
                                 preview: Action.SimplePreview,
                                 date: String,
                                 status: String?) -> ActivityEventViewModel.ActionViewModel {
        return ActivityEventViewModel.ActionViewModel(
            eventType: .walletInitialized,
            amount: "-",
            subamount: nil,
            leftTopDescription: action.address.toShortString(bounceable: true),
            leftBottomDescription: nil,
            date: date,
            rightTopDesription: date,
            status: status,
            comment: nil,
            collectible: nil
        )
    }
    
    func mapSmartContractExecAction(_ action: Action.SmartContractExec,
                                    activityEvent: ActivityEvent,
                                    preview: Action.SimplePreview,
                                    date: String,
                                    status: String?) -> ActivityEventViewModel.ActionViewModel {
        
        let tonInfo = TonInfo()
        var amount = amountFormatter.formatAmount(
            BigInt(integerLiteral: action.tonAttached),
            fractionDigits: tonInfo.fractionDigits,
            maximumFractionDigits: tonInfo.fractionDigits
        )
        
        let sign = action.executor == activityEvent.account ? "-" : "+"
        amount = "\(sign) \(amount) \(tonInfo.symbol)"
        
        return ActivityEventViewModel.ActionViewModel(eventType: .contractExec,
                                                      amount: amount,
                                                      subamount: nil,
                                                      leftTopDescription: action.contract.value,
                                                      leftBottomDescription: nil,
                                                      date: date,
                                                      rightTopDesription: date,
                                                      status: status,
                                                      comment: nil,
                                                      collectible: nil)
    }
    
    func mapItemTransferAction(_ action: Action.NFTItemTransfer,
                               activityEvent: ActivityEvent,
                               preview: Action.SimplePreview,
                               date: String,
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
                                                      date: date,
                                                      rightTopDesription: date,
                                                      status: status,
                                                      comment: action.comment,
                                                      collectible: collectible)
    }
    
    func mapJettonSwapAction(_ action: Action.JettonSwap,
                             activityEvent: ActivityEvent,
                             preview: Action.SimplePreview,
                             date: String,
                             status: String?) -> ActivityEventViewModel.ActionViewModel {
        
        let tonInfo = TonInfo()
        let outAmount: String? = {
            let amount: BigInt
            let fractionDigits: Int
            let symbol: String?
            if let tonOut = action.tonOut {
                amount = BigInt(integerLiteral: tonOut)
                fractionDigits = tonInfo.fractionDigits
                symbol = tonInfo.symbol
            } else if let tokenInfoOut = action.tokenInfoOut {
                amount = action.amountOut
                fractionDigits = tokenInfoOut.fractionDigits
                symbol = tokenInfoOut.symbol
            } else {
                return nil
            }
            var result = "+" + amountFormatter.formatAmount(
                amount,
                fractionDigits: fractionDigits,
                maximumFractionDigits: fractionDigits)
            if let symbol = symbol {
                result += " \(symbol)"
            }
            return result
        }()
        
        let inAmount: String? = {
            let amount: BigInt
            let fractionDigits: Int
            let symbol: String?
            if let tonIn = action.tonIn {
                amount = BigInt(integerLiteral: tonIn)
                fractionDigits = tonInfo.fractionDigits
                symbol = tonInfo.symbol
            } else if let tokenInfoIn = action.tokenInfoIn {
                amount = action.amountIn
                fractionDigits = tokenInfoIn.fractionDigits
                symbol = tokenInfoIn.symbol
            } else {
                return nil
            }
            var result = "-" + amountFormatter.formatAmount(
                amount,
                fractionDigits: fractionDigits,
                maximumFractionDigits: fractionDigits)
            if let symbol = symbol {
                result += " \(symbol)"
            }
            return result
        }()
        
        return ActivityEventViewModel.ActionViewModel(
            eventType: .jettonSwap,
            amount: outAmount,
            subamount: inAmount,
            leftTopDescription: action.user.value,
            leftBottomDescription: nil,
            date: date,
            rightTopDesription: date,
            status: status,
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
