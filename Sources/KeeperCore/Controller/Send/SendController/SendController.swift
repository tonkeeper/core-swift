import Foundation
import BigInt
import TonSwift

public final class SendController {
  
  public var didUpdateFromWallets: (() -> Void)?
  public var didUpdateSelectedFromWallet: ((Int) -> Void)?
  public var didUpdateToWallets: (() -> Void)?
  public var didUpdateInputRecipient: (() -> Void)?
  public var didUpdateIsSendAvailable: ((Bool) -> Void)?
  public var didUpdateAmount: (() -> Void)?
  public var didUpdateComment: (() -> Void)?
  
  struct SendWallet {
    let wallet: Wallet
    let balance: Balance
  }
  
  enum SendRecipient {
    case inputRecipient
    case wallet(index: Int)
  }
  
  public struct SendWalletModel {
    public let id: String
    public let name: String
    public let balance: String
    public let isPickerEnabled: Bool
  }
  
  public struct SendRecipientModel {
    public let value: String
    public let isEmpty: Bool
  }
  
  // MARK: - State
  
  public var selectedWallet: Wallet? {
    selectedFromWallet?.wallet
  }
  
  public private(set) var inputRecipient: Recipient? {
    didSet { didUpdateInputRecipient?() }
  }
  public private(set) var token: Token = .ton {
    didSet {
      guard token != oldValue else { return }
      checkIfSendEnable()
      didUpdateAmount?()
    }
  }
  public private(set) var amount: BigUInt = 0 {
    didSet {
      guard amount != oldValue else { return }
      checkIfSendEnable()
      didUpdateAmount?()
    }
  }
  public private(set) var comment: String? {
    didSet {
      guard comment != oldValue else { return }
      checkIfSendEnable()
      didUpdateComment?()
    }
  }
  public private(set) var isSendAvailable = false {
    didSet {
      didUpdateIsSendAvailable?(isSendAvailable)
    }
  }
  
  private var fromWallets = [SendWallet]() {
    didSet { didUpdateFromWallets?() }
  }
  private var toWallets = [SendWallet]() {
    didSet { didUpdateToWallets?() }
  }
  private var selectedFromWallet: SendWallet?
  private var selectedRecipient: SendRecipient = .inputRecipient
  
  private var isResolvingRecipient = false

  // MARK: - Dependencies

  private let walletsStore: WalletsStore
  private let balanceStore: BalanceStore
  private let knownAccountsStore: KnownAccountsStore
  private let dnsService: DNSService
  private let amountFormatter: AmountFormatter
  
  // MARK: - Init
  
  init(token: Token,
       walletsStore: WalletsStore,
       balanceStore: BalanceStore,
       knownAccountsStore: KnownAccountsStore,
       dnsService: DNSService,
       amountFormatter: AmountFormatter) {
    self.token = token
    self.walletsStore = walletsStore
    self.balanceStore = balanceStore
    self.knownAccountsStore = knownAccountsStore
    self.dnsService = dnsService
    self.amountFormatter = amountFormatter
  }
  
  public func start() {
    reloadWallets()
    didUpdateComment?()
    didUpdateAmount?()
  }
  
  public func setInputRecipient(with input: String) {
    self.isResolvingRecipient = true
    Task {
      let inputRecipient: Recipient?
      let knownAccounts = (try? await knownAccountsStore.getKnownAccounts()) ?? []
      if let friendlyAddress = try? FriendlyAddress(string: input) {
        inputRecipient = Recipient(
          recipientAddress: .friendly(
            friendlyAddress
          ),
          isKnownAccount: knownAccounts.contains(where: { $0.address == friendlyAddress.address })
        )
      } else if let rawAddress = try? Address.parse(input) {
        inputRecipient = Recipient(
          recipientAddress: .raw(
            rawAddress
          ),
          isKnownAccount: knownAccounts.contains(where: { $0.address == rawAddress })
        )
      } else if let domain = try? await dnsService.resolveDomainName(input) {
        inputRecipient = Recipient(
          recipientAddress: .domain(domain),
          isKnownAccount: knownAccounts.contains(where: { $0.address == domain.friendlyAddress.address })
        )
      } else {
        inputRecipient = nil
      }
      await MainActor.run {
        self.isResolvingRecipient = false
        self.inputRecipient = inputRecipient
      }
    }
  }
  
  public func setInputRecipient(_ recipient: Recipient?) {
    self.inputRecipient = recipient
  }
  
  public func setToken(_ token: Token, amount: BigUInt) {
    self.amount = amount
  }
  
  public func setComment(_ comment: String?) {
    self.comment = comment
  }
  
  public func getFromWalletsModels() -> [SendWalletModel] {
    getWalletsModels(wallets: fromWallets)
  }
  
  public func getToWalletsModels() -> [SendWalletModel] {
    getWalletsModels(wallets: toWallets)
  }
  
  public func getInputRecipientModel() -> SendRecipientModel {
    guard let inputRecipient = inputRecipient else {
      return SendRecipientModel(value: "Address or name", isEmpty: true)
    }
    switch inputRecipient.recipientAddress {
    case .friendly(let friendlyAddress):
      return SendRecipientModel(value: friendlyAddress.toString(), isEmpty: false)
    case .raw(let address):
      return SendRecipientModel(value: address.toRaw(), isEmpty: false)
    case .domain(let domainRecipient):
      return SendRecipientModel(value: domainRecipient.domain, isEmpty: false)
    }
  }
  
  public func getAmountValue() -> String {
    switch token {
    case .ton:
      return amountFormatter.formatAmount(
        amount,
        fractionDigits: TonInfo.fractionDigits,
        maximumFractionDigits: TonInfo.fractionDigits,
        symbol: TonInfo.symbol
      )
    case .jetton(let jettonInfo):
      return amountFormatter.formatAmount(
        amount,
        fractionDigits: jettonInfo.fractionDigits,
        maximumFractionDigits: jettonInfo.fractionDigits,
        symbol: jettonInfo.symbol
      )
    }
  }
  
  public func getComment() -> String? {
    comment
  }
  
  public func setWalletSelectedSender(index: Int) {
    guard fromWallets.count > index else { return }
    selectedFromWallet = fromWallets[index]
    reloadToWallets()
    checkIfSendEnable()
  }
  
  public func setWalletSelectedRecipient(index: Int) {
    guard toWallets.count > index else { return }
    selectedRecipient = .wallet(index: index)
    checkIfSendEnable()
  }
  
  public func setInputRecipientSelectedRecipient() {
    selectedRecipient = .inputRecipient
    checkIfSendEnable()
  }
}

private extension SendController {
  func reloadWallets() {
    reloadFromWallets()
    reloadToWallets()
    checkIfSendEnable()
  }
  
  func reloadFromWallets() {
    var fromWallets = [SendWallet]()
    var selectedFromWallet: SendWallet?
    var selectedIndex = 0
    for (index, wallet) in walletsStore.wallets.enumerated() {
      let balance: Balance
      do {
        balance = try balanceStore.getBalance(wallet: wallet).balance
      } catch {
        balance = Balance(tonBalance: TonBalance(amount: 0), jettonsBalance: [])
      }
      let sendWallet = SendWallet(
        wallet: wallet,
        balance: balance
      )
      fromWallets.append(sendWallet)
      if wallet == walletsStore.activeWallet {
        selectedFromWallet = sendWallet
        selectedIndex = index
      }
    }
    self.fromWallets = fromWallets
    self.selectedFromWallet = selectedFromWallet
    self.didUpdateSelectedFromWallet?(selectedIndex)
  }
  
  func reloadToWallets() {
    toWallets = fromWallets.filter { $0.wallet != selectedFromWallet?.wallet }
  }
  
  func checkIfSendEnable() {
    let isRecipientValid: Bool = {
      switch selectedRecipient {
      case .wallet: return true
      case .inputRecipient:
        guard let inputRecipient else { return false }
        switch inputRecipient.recipientAddress {
        case .friendly:
          return true
        case .raw:
          return true
        case .domain:
          return true
        }
      }
    }()
    
    let isAmountValid: Bool = {
      guard let selectedFromWallet else { return false }
      let balance: Balance
      do {
        balance = try balanceStore.getBalance(wallet: selectedFromWallet.wallet).balance
      } catch {
        balance = Balance(tonBalance: TonBalance(amount: 0), jettonsBalance: [])
      }
      switch token {
      case .ton:
        return BigUInt(balance.tonBalance.amount) >= amount
      case .jetton(let jettonInfo):
        let jettonBalance = balance.jettonsBalance.first(where: { $0.amount.jettonInfo == jettonInfo })?.amount.quantity ?? 0
        return jettonBalance >= amount
      }
    }()
    
    let isCommentValid: Bool = {
      switch selectedRecipient {
      case .wallet: return true
      case .inputRecipient:
        guard let inputRecipient else { return false }
        return !inputRecipient.isKnownAccount || !(comment ?? "").isEmpty
      }
    }()
    
    let isValid = isRecipientValid && isAmountValid && isCommentValid
    self.isSendAvailable = isValid
  }

  func getWalletsModels(wallets: [SendWallet]) -> [SendWalletModel] {
    return wallets.map { sendWallet in
      let name = "\(sendWallet.wallet.metaData.emoji)\(sendWallet.wallet.metaData.label)"
      let balance: String
      switch token {
      case .ton:
        balance = amountFormatter.formatAmount(
          BigUInt(integerLiteral: UInt64(sendWallet.balance.tonBalance.amount)),
          fractionDigits: TonInfo.fractionDigits,
          maximumFractionDigits: 2,
          symbol: TonInfo.symbol
        )
      case .jetton(let jettonInfo):
        let amount: BigUInt
        if let jettonBalance = sendWallet.balance.jettonsBalance.first(where: { $0.amount.jettonInfo == jettonInfo }) {
          amount = jettonBalance.amount.quantity
        } else {
          amount = 0
        }
        balance = amountFormatter.formatAmount(
          amount,
          fractionDigits: jettonInfo.fractionDigits,
          maximumFractionDigits: 2,
          symbol: jettonInfo.symbol
        )
      }
      return SendWalletModel(
        id: UUID().uuidString,
        name: name,
        balance: balance,
        isPickerEnabled: !sendWallet.balance.jettonsBalance.isEmpty
      )
    }
  }
}
