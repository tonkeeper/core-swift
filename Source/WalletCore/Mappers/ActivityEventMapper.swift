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
    
    func mapActivityEvent(_ event: ActivityEvent, dateFormat: String) -> ActivityEventViewModel {
        let eventDate = Date(timeIntervalSince1970: event.timestamp)
        dateFormatter.dateFormat = dateFormat
        let date = dateFormatter.string(from: eventDate)
        let actionViewModels = event.actions.map { action in
            mapAction(action, activityEvent: event, date: date)
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
    func mapAction(_ action: Action, activityEvent: ActivityEvent, date: String) -> ActivityEventViewModel.ActionViewModel {
        
        let dummy = ActivityEventViewModel.ActionViewModel(eventType: .endOfAuction,
                                                           amount: "420",
                                                           leftTopDescription: "Left",
                                                           leftBottomDescription: "Right",
                                                           date: "Time",
                                                           rightTopDesription: "Right",
                                                           status: "Status",
                                                           comment: "Comment")
        
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
            return dummy
        case .contractDeploy(let contractDeploy):
            return dummy
        case .depositStake(let depositStake):
            return dummy
        case .jettonSwap(let jettonSwap):
            return dummy
        case .nftItemTransfer(let nftItemTransfer):
            return dummy
        case .nftPurchase(let nftPurchase):
            return dummy
        case .recoverStake(let recoverStake):
            return dummy
        case .smartContract(let smartContract):
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
                                                      rightTopDesription: nil,
                                                      status: status,
                                                      comment: action.comment)
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
                                                      rightTopDesription: nil,
                                                      status: status,
                                                      comment: action.comment)
    }
}
