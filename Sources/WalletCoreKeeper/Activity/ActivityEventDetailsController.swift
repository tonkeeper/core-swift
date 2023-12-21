import Foundation
import BigInt
import WalletCoreCore

public final class ActivityEventDetailsController {
    
    public struct Model {
        public struct ListItem {
            public let title: String
            public let topValue: String
            public let bottomValue: String?
            
            public init(title: String, topValue: String, bottomValue: String? = nil) {
                self.title = title
                self.topValue = topValue
                self.bottomValue = bottomValue
            }
        }
        public let title: String?
        public let aboveTitle: String?
        public let date: String?
        public let fiatPrice: String?
        public let nftName: String?
        public let nftCollectionName: String?
        public let status: String?
        
        public let listItems: [ListItem]
        
        init(title: String? = nil, aboveTitle: String? = nil, date: String? = nil, fiatPrice: String? = nil, nftName: String? = nil, nftCollectionName: String? = nil, status: String? = nil, listItems: [ListItem] = []) {
            self.title = title
            self.aboveTitle = aboveTitle
            self.date = date
            self.fiatPrice = fiatPrice
            self.nftName = nftName
            self.nftCollectionName = nftCollectionName
            self.status = status
            self.listItems = listItems
        }
    }
    
    private let action: ActivityEventAction
    private let amountMapper: AccountEventActionAmountMapper
    private let ratesStore: RatesStore
    private let walletProvider: WalletProvider
    
    private let rateConverter = RateConverter()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.init(identifier: "EN")
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter
    }()
    
    init(action: ActivityEventAction,
         amountMapper: AccountEventActionAmountMapper,
         ratesStore: RatesStore,
         walletProvider: WalletProvider) {
        self.action = action
        self.amountMapper = amountMapper
        self.ratesStore = ratesStore
        self.walletProvider = walletProvider
    }
    
    public var transactionHash: String {
        String(action.accountEvent.eventId.prefix(8))
    }
    
    public var transactionURL: URL {
        URL(string: "https://tonviewer.com/transaction/\(action.accountEvent.eventId)")!
    }
    
    public var model: Model {
        mapModel()
    }
}

private extension ActivityEventDetailsController {
    func mapModel() -> Model {
        let eventAction = action.accountEvent.actions[action.actionIndex]
        let date = dateFormatter.string(from: Date(timeIntervalSince1970: action.accountEvent.timestamp))
        
        let fee = amountMapper.mapAmount(
            amount: BigInt(integerLiteral: abs(action.accountEvent.fee)),
            fractionDigits: TonInfo().fractionDigits,
            maximumFractionDigits: TonInfo().fractionDigits,
            type: .none,
            currency: .TON)
        let fiatFee = tonFiatString(amount: BigInt(action.accountEvent.fee))
        let feeListItem = Model.ListItem(
            title: "Fee",
            topValue: fee,
            bottomValue: fiatFee)
        
        let title: String?
        switch eventAction.type {
        case let .auctionBid(auctionBid):
            title = "none"
        case let .contractDeploy(contractDeploy):
            return mapContractDeploy(
                activityEvent: action.accountEvent,
                action: contractDeploy,
                date: date,
                feeListItem: feeListItem,
                status: eventAction.status)
        case let .depositStake(depositStake):
            return mapDepositStake(
                activityEvent: action.accountEvent,
                action: depositStake,
                date: date,
                feeListItem: feeListItem,
                status: eventAction.status)
        case let .jettonBurn(jettonBurn):
            return mapJettonBurn(
                activityEvent: action.accountEvent,
                action: jettonBurn,
                date: date,
                feeListItem: feeListItem,
                status: eventAction.status)
        case let .jettonMint(jettonMint):
            return mapJettonMint(
                activityEvent: action.accountEvent,
                action: jettonMint,
                date: date,
                feeListItem: feeListItem,
                status: eventAction.status)
        case let .jettonSwap(jettonSwap):
            return mapJettonSwap(
                activityEvent: action.accountEvent,
                action: jettonSwap,
                date: date,
                feeListItem: feeListItem,
                status: eventAction.status)
        case let .jettonTransfer(jettonTransfer):
            return mapJettonTransfer(
                activityEvent: action.accountEvent,
                action: jettonTransfer,
                date: date,
                feeListItem: feeListItem,
                status: eventAction.status)
        case let .nftItemTransfer(nftItemTransfer):
            return mapNFTTransfer(
                activityEvent: action.accountEvent,
                nftTransfer: nftItemTransfer,
                date: date,
                feeListItem: feeListItem,
                status: eventAction.status)
        case let .nftPurchase(nftPurchase):
            return mapNFTPurchase(
                activityEvent: action.accountEvent,
                action: nftPurchase,
                date: date,
                feeListItem: feeListItem,
                status: eventAction.status)
        case let .smartContractExec(smartContractExec):
            return mapSmartContractExec(
                activityEvent: action.accountEvent,
                smartContractExec: smartContractExec,
                date: date,
                feeListItem: feeListItem,
                status: eventAction.status)
        case let .tonTransfer(tonTransfer):
            return mapTonTransfer(
                activityEvent: action.accountEvent,
                tonTransfer: tonTransfer, 
                date: date,
                feeListItem: feeListItem,
                status: eventAction.status)
        case let .withdrawStake(withdrawStake):
            title = "none"
        case let .withdrawStakeRequest(withdrawStakeRequest):
            return mapWithdrawStakeRequest(
                activityEvent: action.accountEvent,
                action: withdrawStakeRequest,
                date: date,
                feeListItem: feeListItem,
                status: eventAction.status)
        case .subscribe:
            title = "None"
        case .unsubscribe:
            title = "None"
        }
        
        return Model(title: title, date: nil, fiatPrice: nil, listItems: [])
    }
    
    func mapTonTransfer(activityEvent: AccountEvent,
                        tonTransfer: Action.TonTransfer,
                        date: String,
                        feeListItem: Model.ListItem,
                        status: Status) -> Model {
        let tonInfo = TonInfo()
        let amountType: AccountEventActionAmountMapperActionType
        let actionString: String
        
        let nameTitle: String
        let nameValue: String?
        let addressTitle: String
        let addressValue: String
        
        if activityEvent.isScam {
            amountType = .income
            actionString = .received
            addressTitle = .senderAddress
            nameTitle = .sender
            nameValue = tonTransfer.sender.name
            addressValue = tonTransfer.sender.address.toString(bounceable: !tonTransfer.sender.isWallet)
        } else if tonTransfer.recipient == activityEvent.account {
            amountType = .income
            actionString = .received
            addressTitle = .senderAddress
            nameTitle = .sender
            nameValue = tonTransfer.sender.name
            addressValue = tonTransfer.sender.address.toString(bounceable: !tonTransfer.sender.isWallet)
        } else {
            amountType = .outcome
            actionString = .sent
            addressTitle = .recipientAddress
            nameTitle = .recipient
            nameValue = tonTransfer.recipient.name
            addressValue = tonTransfer.recipient.address.toString(bounceable: !tonTransfer.sender.isWallet)
        }
        
        let fiatPrice = tonFiatString(amount: BigInt(tonTransfer.amount))
        
        let title = amountMapper.mapAmount(
            amount: BigInt(integerLiteral: tonTransfer.amount),
            fractionDigits: tonInfo.fractionDigits,
            maximumFractionDigits: 2,
            type: amountType,
            currency: .TON)
        let dateString = "\(actionString) on \(date)"
        
        var listItems = [Model.ListItem]()
        
        if let nameValue = nameValue {
            listItems.append(Model.ListItem(title: nameTitle, topValue: nameValue))
        }
        listItems.append(Model.ListItem(title: addressTitle, topValue: addressValue))
        listItems.append(feeListItem)
        
        return Model(
            title: title,
            date: dateString,
            fiatPrice: fiatPrice,
            status: status.rawValue,
            listItems: listItems
        )
    }
    
    func mapNFTTransfer(activityEvent: AccountEvent,
                        nftTransfer: Action.NFTItemTransfer,
                        date: String,
                        feeListItem: Model.ListItem,
                        status: Status) -> Model {
        let actionString: String
        
        let nameTitle: String
        let nameValue: String?
        let addressTitle: String
        let addressValue: String?
        
        if activityEvent.isScam {
            actionString = .received
            addressTitle = .senderAddress
            nameTitle = .sender
            nameValue = nftTransfer.sender?.name
            addressValue = nftTransfer.sender?.address.toString(bounceable: !(nftTransfer.sender?.isWallet ?? false))
        } else if nftTransfer.recipient == activityEvent.account {
            actionString = .received
            addressTitle = .senderAddress
            nameTitle = .sender
            nameValue = nftTransfer.sender?.name
            addressValue = nftTransfer.sender?.address.toString(bounceable: !(nftTransfer.sender?.isWallet ?? false))
        } else {
            actionString = .sent
            addressTitle = .recipientAddress
            nameTitle = .recipient
            nameValue = nftTransfer.recipient?.name
            addressValue = nftTransfer.recipient?.address.toString(bounceable: !(nftTransfer.recipient?.isWallet ?? false))
        }
        
        let title = "NFT"
        let dateString = "\(actionString) on \(date)"
        
        var listItems = [Model.ListItem]()
        
        if let nameValue = nameValue {
            listItems.append(Model.ListItem(title: nameTitle, topValue: nameValue))
        }
        if let addressValue = addressValue {
            listItems.append(Model.ListItem(title: addressTitle, topValue: addressValue))
        }
        listItems.append(feeListItem)
        
        return Model(
            title: title,
            date: dateString,
            status: status.rawValue,
            listItems: listItems
        )
    }
    
    func mapNFTPurchase(activityEvent: AccountEvent,
                        action: Action.NFTPurchase,
                        date: String,
                        feeListItem: Model.ListItem,
                        status: Status) -> Model {
        let nftName = action.collectible.name
        let nftCollectionName = action.collectible.collection?.name
        let fiatPrice = tonFiatString(amount: action.price)
        let title = amountMapper.mapAmount(
            amount: action.price,
            fractionDigits: TonInfo().fractionDigits,
            maximumFractionDigits: 2,
            type: .outcome,
            currency: .TON)
        let dateString = "Purchased on \(date)"
        
        var listItems = [Model.ListItem]()
        
        if let senderName = action.seller.name {
            listItems.append(Model.ListItem(title: "Sender", topValue: senderName))
        }
        listItems.append(Model.ListItem(title: "Sender address", topValue: action.seller.address.toString(bounceable: !action.seller.isWallet)))
        listItems.append(feeListItem)
        
        return Model(
            title: title,
            date: dateString,
            fiatPrice: fiatPrice,
            nftName: nftName,
            nftCollectionName: nftCollectionName,
            status: status.rawValue,
            listItems: listItems
        )
    }
    
    func mapContractDeploy(activityEvent: AccountEvent,
                           action: Action.ContractDeploy,
                           date: String,
                           feeListItem: Model.ListItem,
                           status: Status) -> Model {
        let title = "Wallet initialized"
        
        let listItems = [feeListItem]

        return Model(
            title: title,
            date: date,
            fiatPrice: nil,
            status: status.rawValue,
            listItems: listItems
        )
    }
    
    func mapSmartContractExec(activityEvent: AccountEvent,
                              smartContractExec: Action.SmartContractExec,
                              date: String,
                              feeListItem: Model.ListItem,
                              status: Status) -> Model {
        let tonInfo = TonInfo()
        let fiatPrice = tonFiatString(amount: BigInt(smartContractExec.tonAttached))

        let title = amountMapper.mapAmount(
            amount: BigInt(integerLiteral: smartContractExec.tonAttached),
            fractionDigits: tonInfo.fractionDigits,
            maximumFractionDigits: 2,
            type: .outcome,
            currency: .TON)
        let dateString = "Called contract on \(date)"
        
        var listItems = [Model.ListItem]()
        listItems.append(Model.ListItem(title: "Address", topValue: smartContractExec.contract.address.toString()))
        listItems.append(Model.ListItem(title: "Operation", topValue: smartContractExec.operation))
        listItems.append(feeListItem)
        if let payload = smartContractExec.payload {
            listItems.append(Model.ListItem(title: "Payload", topValue: payload))
        }
        
        return Model(
            title: title,
            date: dateString,
            fiatPrice: fiatPrice,
            status: status.rawValue,
            listItems: listItems
        )
    }
    
    func mapJettonSwap(activityEvent: AccountEvent,
                       action: Action.JettonSwap,
                       date: String,
                       feeListItem: Model.ListItem,
                       status: Status) -> Model {
        let tonInfo = TonInfo()
        let title: String? = {
            let amount: BigInt
            let fractionDigits: Int
            let maximumFractionDigits: Int
            let symbol: String?
            if let tonOut = action.tonOut {
                amount = BigInt(integerLiteral: tonOut)
                fractionDigits = tonInfo.fractionDigits
                maximumFractionDigits = tonInfo.fractionDigits
                symbol = tonInfo.symbol
            } else if let tokenInfoOut = action.tokenInfoOut {
                amount = action.amountOut
                fractionDigits = tokenInfoOut.fractionDigits
                maximumFractionDigits = tokenInfoOut.fractionDigits
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
        
        let aboveTitle: String? = {
            let amount: BigInt
            let fractionDigits: Int
            let maximumFractionDigits: Int
            let symbol: String?
            if let tonIn = action.tonIn {
                amount = BigInt(integerLiteral: tonIn)
                fractionDigits = tonInfo.fractionDigits
                maximumFractionDigits = tonInfo.fractionDigits
                symbol = tonInfo.symbol
            } else if let tokenInfoIn = action.tokenInfoIn {
                amount = action.amountIn
                fractionDigits = tokenInfoIn.fractionDigits
                maximumFractionDigits = tokenInfoIn.fractionDigits
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

        let dateString = "Swapped on \(date)"
        
        var listItems = [Model.ListItem]()
        listItems.append(Model.ListItem(title: .recipient, topValue: action.user.address.toString(bounceable: !action.user.isWallet)))
        listItems.append(feeListItem)
        
        return Model(
            title: title,
            aboveTitle: aboveTitle,
            date: dateString,
            fiatPrice: nil,
            status: status.rawValue,
            listItems: listItems
        )
    }
    
    func mapWithdrawStakeRequest(activityEvent: AccountEvent,
                                 action: Action.WithdrawStakeRequest,
                                 date: String,
                                 feeListItem: Model.ListItem,
                                 status: Status) -> Model {
        let title = "Unstake Request"
        let dateString = "\(date)"
        
        var listItems = [Model.ListItem]()
        if let senderName = action.pool.name {
            listItems.append(Model.ListItem(title: .sender, topValue: senderName))
        }
        listItems.append(Model.ListItem(title: .senderAddress, topValue: action.pool.address.toString(bounceable: !action.pool.isWallet)))
        if let amount = action.amount {
            let formattedAmount = amountMapper.mapAmount(
                amount: BigInt(integerLiteral: amount),
                fractionDigits: TonInfo().fractionDigits,
                maximumFractionDigits: TonInfo().fractionDigits,
                type: .none,
                currency: .TON)
            listItems.append(Model.ListItem(title: "Unstake amount", topValue: formattedAmount))
        }
        
        listItems.append(feeListItem)
        
        return Model(
            title: title,
            aboveTitle: nil,
            date: dateString,
            fiatPrice: nil,
            status: status.rawValue,
            listItems: listItems
        )
    }
    
    func mapDepositStake(activityEvent: AccountEvent,
                         action: Action.DepositStake,
                         date: String,
                         feeListItem: Model.ListItem,
                         status: Status) -> Model {
        let title = amountMapper.mapAmount(
            amount: BigInt(integerLiteral: action.amount),
            fractionDigits: TonInfo().fractionDigits,
            maximumFractionDigits: TonInfo().fractionDigits,
            type: .outcome,
            currency: .TON)
        let dateString = "Staked on \(date)"
        
        var listItems = [Model.ListItem]()
        if let senderName = action.pool.name {
            listItems.append(Model.ListItem(title: .recipient, topValue: senderName))
        }
        listItems.append(Model.ListItem(title: .recipientAddress, topValue: action.pool.address.toString(bounceable: !action.pool.isWallet)))
        listItems.append(feeListItem)
        
        return Model(
            title: title,
            aboveTitle: nil,
            date: dateString,
            fiatPrice: nil,
            status: status.rawValue,
            listItems: listItems
        )
    }
    
    func mapJettonMint(activityEvent: AccountEvent,
                         action: Action.JettonMint,
                         date: String,
                         feeListItem: Model.ListItem,
                       status: Status) -> Model {
        let title = amountMapper.mapAmount(
            amount: action.amount,
            fractionDigits: action.tokenInfo.fractionDigits,
            maximumFractionDigits: action.tokenInfo.fractionDigits,
            type: .income,
            symbol: action.tokenInfo.symbol)
        let dateString = "\(String.received) on \(date)"
        let fiatPrice = tonFiatString(amount: action.amount)
        var listItems = [Model.ListItem]()
        if let recipientName = action.recipient.name {
            listItems.append(Model.ListItem(title: .recipient, topValue: recipientName))
        }
        listItems.append(Model.ListItem(title: .recipientAddress, topValue: action.recipient.address.toString(bounceable: !action.recipient.isWallet)))
        listItems.append(feeListItem)
        
        return Model(
            title: title,
            aboveTitle: nil,
            date: dateString,
            fiatPrice: fiatPrice,
            status: status.rawValue,
            listItems: listItems
        )
    }
    
    func mapJettonTransfer(activityEvent: AccountEvent,
                           action: Action.JettonTransfer,
                           date: String,
                           feeListItem: Model.ListItem,
                           status: Status) -> Model {
        let amountType: AccountEventActionAmountMapperActionType
        let actionString: String
        
        let nameTitle: String
        let nameValue: String?
        let addressTitle: String
        let addressValue: String?
        
        if activityEvent.isScam {
            amountType = .income
            actionString = .received
            addressTitle = .senderAddress
            nameTitle = .sender
            nameValue = action.sender?.name
            addressValue = action.sender?.address.toString(bounceable: !(action.sender?.isWallet ?? false))
        } else if action.recipient == activityEvent.account {
            amountType = .income
            actionString = .received
            addressTitle = .senderAddress
            nameTitle = .sender
            nameValue = action.sender?.name
            addressValue = action.sender?.address.toString(bounceable: !(action.sender?.isWallet ?? false))
        } else {
            amountType = .outcome
            actionString = .sent
            addressTitle = .recipientAddress
            nameTitle = .recipient
            nameValue = action.recipient?.name
            addressValue = action.recipient?.address.toString(bounceable: !(action.recipient?.isWallet ?? false))
        }
        
        let fiatPrice = tonFiatString(amount: action.amount)
        
        let title = amountMapper.mapAmount(
            amount: action.amount,
            fractionDigits: action.tokenInfo.fractionDigits,
            maximumFractionDigits: action.tokenInfo.fractionDigits,
            type: amountType,
            symbol: action.tokenInfo.symbol)
        let dateString = "\(actionString) on \(date)"
        
        var listItems = [Model.ListItem]()
        
        if let nameValue = nameValue {
            listItems.append(Model.ListItem(title: nameTitle, topValue: nameValue))
        }
        if let addressValue = addressValue {
            listItems.append(Model.ListItem(title: addressTitle, topValue: addressValue))
        }
        listItems.append(feeListItem)
        
        return Model(
            title: title,
            date: dateString,
            fiatPrice: fiatPrice,
            status: status.rawValue,
            listItems: listItems
        )
    }
    
    func mapJettonBurn(activityEvent: AccountEvent,
                       action: Action.JettonBurn,
                       date: String,
                       feeListItem: Model.ListItem,
                       status: Status) -> Model {
        let title = amountMapper.mapAmount(
            amount: action.amount,
            fractionDigits: action.tokenInfo.fractionDigits,
            maximumFractionDigits: action.tokenInfo.fractionDigits,
            type: .outcome,
            symbol: action.tokenInfo.symbol)
        let dateString = "Burned on \(date)"
        let fiatPrice = tonFiatString(amount: action.amount)
        let listItems = [feeListItem]
        
        return Model(
            title: title,
            aboveTitle: nil,
            date: dateString,
            fiatPrice: fiatPrice,
            status: status.rawValue,
            listItems: listItems
        )
    }
    
    func tonFiatString(amount: BigInt) -> String? {
        guard let wallet = try? walletProvider.activeWallet,
              let tonRate = ratesStore.rates.ton.first(where: { $0.currency == wallet.currency }) else {
            return nil
        }
        
        let amount = abs(amount)
        let fiat = rateConverter.convert(
            amount: amount, 
            amountFractionLength: TonInfo().fractionDigits,
            rate: tonRate
        )
        return amountMapper.mapAmount(
            amount: fiat.amount,
            fractionDigits: fiat.fractionLength,
            maximumFractionDigits: 2,
            type: .none,
            currency: wallet.currency)
    }
}

private extension String {
    static let received = "Received"
    static let sent = "Sent"
    static let sender = "Sender"
    static let recipient = "Recipient"
    static let senderAddress = "Sender address"
    static let recipientAddress = "Recipient address"
}
