//
//  ActivityEventMapper.swift
//  
//
//  Created by Grigory on 4.8.23..
//

import Foundation

struct ActivityEventMapper {
    private let dateFormatter: DateFormatter
    
    init(dateFormatter: DateFormatter) {
        self.dateFormatter = dateFormatter
    }
    
    func mapActivityEvent(_ event: ActivityEvent, dateFormat: String, collectibles: Collectibles) -> ActivityEventViewModel {
        let eventDate = Date(timeIntervalSince1970: event.timestamp)
        dateFormatter.dateFormat = dateFormat
        let date = dateFormatter.string(from: eventDate)
        let actionViewModels = event.actions.map { action in
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
    func mapAction(_ action: Action, activityEvent: ActivityEvent, date: String, collectibles: Collectibles) -> ActivityEventViewModel.ActionViewModel {
        
        let dummy = ActivityEventViewModel.ActionViewModel(eventType: .endOfAuction,
                                                           amount: "420",
                                                           leftTopDescription: "Left",
                                                           leftBottomDescription: "Right",
                                                           date: "Time",
                                                           rightTopDesription: "Right",
                                                           status: "Status",
                                                           comment: "Comment",
                                                           collectible: nil)
        
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
        case .auctionBid(let auctionBid):
            return mapAuctionBidAction(auctionBid,
                                       activityEvent: activityEvent,
                                       preview: action.preview,
                                       date: date,
                                       status: action.status.rawValue)
        case .nftPurchase(let nftPurchase):
            print(nftPurchase)
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
            return dummy
        case .jettonSwap(let jettonSwap):
            return dummy
        case .recoverStake(let recoverStake):
            return dummy
        case .subscribe(let subscribe):
            return dummy
        case .unsubscribe(let unsubscribe):
            return dummy
        }
    }
    
    func mapTonTransferAction(_ action: Action.TonTransfer,
                              activityEvent: ActivityEvent,
                              preview: Action.SimplePreview,
                              date: String,
                              status: String?) -> ActivityEventViewModel.ActionViewModel {
        let eventType: ActivityEventViewModel.ActionViewModel.ActionType
        let leftTopDescription: String
        if activityEvent.isScam {
            eventType = .spam
            leftTopDescription = action.sender.address.shortString
        } else if action.sender == activityEvent.account {
            eventType = .sent
            leftTopDescription = action.recipient.address.shortString
        } else {
            eventType = .receieved
            leftTopDescription = action.sender.address.shortString
        }
        
        
        return ActivityEventViewModel.ActionViewModel(eventType: eventType,
                                                      amount: preview.value,
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
        
        if activityEvent.isScam {
            eventType = .spam
            leftTopDescription = action.sender?.address.shortString ?? nil
        } else if action.sender == activityEvent.account {
            eventType = .sent
            leftTopDescription = action.recipient?.address.shortString ?? nil
        } else {
            eventType = .receieved
            leftTopDescription = action.sender?.address.shortString ?? nil
        }
        
        return ActivityEventViewModel.ActionViewModel(eventType: eventType,
                                                      amount: preview.value,
                                                      leftTopDescription: leftTopDescription,
                                                      leftBottomDescription: nil,
                                                      date: date,
                                                      rightTopDesription: date,
                                                      status: status,
                                                      comment: action.comment,
                                                      collectible: nil)
    }
    
    func mapAuctionBidAction(_ action: Action.AuctionBid,
                             activityEvent: ActivityEvent,
                             preview: Action.SimplePreview,
                             date: String,
                             status: String?) -> ActivityEventViewModel.ActionViewModel {
        
        var collectible: ActivityEventViewModel.ActionViewModel.CollectibleViewModel?
        if let actionCollectible = action.collectible {
            collectible = ActivityEventViewModel.ActionViewModel.CollectibleViewModel(name: actionCollectible.name, collectionName: actionCollectible.collection?.name, image: .url(actionCollectible.imageURL))
        }
        
        return ActivityEventViewModel.ActionViewModel(eventType: .bid,
                                                      amount: preview.value,
                                                      leftTopDescription: action.bidder.address.shortString,
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
            image: .url(action.collectible.imageURL)
        )
        
        return ActivityEventViewModel.ActionViewModel(eventType: .nftPurchase,
                                                      amount: preview.value,
                                                      leftTopDescription: action.seller.address.shortString,
                                                      leftBottomDescription: nil,
                                                      date: date,
                                                      rightTopDesription: date,
                                                      status: status,
                                                      comment: nil,
                                                      collectible: collectibleViewModel)
    }
    
    func mapContractDeployAction(_ action: Action.ContractDeploy,
                                 activityEvent: ActivityEvent,
                                 preview: Action.SimplePreview,
                                 date: String,
                                 status: String?) -> ActivityEventViewModel.ActionViewModel {
        return ActivityEventViewModel.ActionViewModel(eventType: .walletInitialized,
                                                      amount: "-",
                                                      leftTopDescription: action.address.shortString,
                                                      leftBottomDescription: nil,
                                                      date: date,
                                                      rightTopDesription: date,
                                                      status: status,
                                                      comment: nil,
                                                      collectible: nil)
    }
    
    func mapSmartContractExecAction(_ action: Action.SmartContractExec,
                                    activityEvent: ActivityEvent,
                                    preview: Action.SimplePreview,
                                    date: String,
                                    status: String?) -> ActivityEventViewModel.ActionViewModel {
        return ActivityEventViewModel.ActionViewModel(eventType: .contractExec,
                                                      amount: preview.value,
                                                      leftTopDescription: action.operation,
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
                                image: .url(actionCollectible.imageURL))
        }
        
        return ActivityEventViewModel.ActionViewModel(eventType: eventType,
                                                      amount: "NFT",
                                                      leftTopDescription: leftTopDescription,
                                                      leftBottomDescription: nil,
                                                      date: date,
                                                      rightTopDesription: date,
                                                      status: status,
                                                      comment: action.comment,
                                                      collectible: collectible)
    }
}

private extension WalletAccount {
    var value: String {
        if let name = name { return name }
        return address.shortString
    }
}
