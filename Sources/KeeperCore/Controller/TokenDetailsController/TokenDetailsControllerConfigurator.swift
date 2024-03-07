import Foundation
import BigInt

protocol TokenDetailsControllerConfigurator {
  func getTokenModel(balance: Balance, rates: Rates, currency: Currency) -> TokenDetailsController.TokenModel
}

struct TonTokenDetailsControllerConfigurator: TokenDetailsControllerConfigurator {
  private let mapper: TokenDetailsMapper
  
  init(mapper: TokenDetailsMapper) {
    self.mapper = mapper
  }
  
  func getTokenModel(balance: Balance, rates: Rates, currency: Currency) -> TokenDetailsController.TokenModel {
    let amount = mapper.mapTonBalance(
      amount: balance.tonBalance.amount,
      tonRates: rates.ton,
      currency: currency
    )
    
    return TokenDetailsController.TokenModel(
      tokenTitle: TonInfo.name,
      tokenSubtitle: nil,
      image: .ton,
      tokenAmount: amount.tokenAmount,
      convertedAmount: amount.convertedAmount,
      buttons: [.send(.ton), .receive(.ton), .buySell]
    )
  }
}

struct JettonTokenDetailsControllerConfigurator: TokenDetailsControllerConfigurator {
  
  private let jettonItem: JettonItem
  private let mapper: TokenDetailsMapper
  
  init(jettonItem: JettonItem,
       mapper: TokenDetailsMapper) {
    self.jettonItem = jettonItem
    self.mapper = mapper
  }
  
  func getTokenModel(balance: Balance, rates: Rates, currency: Currency) -> TokenDetailsController.TokenModel {
    let subtitle: String?
    switch jettonItem.jettonInfo.verification {
    case .whitelist:
      subtitle = nil
    case .none:
      subtitle = "Unverified Token"
    case .blacklist:
      subtitle = "Unverified Token"
    }
    
    var jettonAmount: BigUInt = 0
    if let jettonBalance = balance.jettonsBalance.first(where: { $0.item.jettonInfo == jettonItem.jettonInfo }) {
      jettonAmount = jettonBalance.quantity
    }
    
    let jettonRates = rates.jettonsRates.first(where: { $0.jettonInfo == jettonItem.jettonInfo })?.rates ?? []
    
    let amount = mapper.mapJettonBalance(
      jettonInfo: jettonItem.jettonInfo,
      jettonAmount: jettonAmount,
      rates: jettonRates,
      currency: currency
    )
    
    return TokenDetailsController.TokenModel(
      tokenTitle: jettonItem.jettonInfo.name,
      tokenSubtitle: subtitle,
      image: .url(jettonItem.jettonInfo.imageURL),
      tokenAmount: amount.tokenAmount,
      convertedAmount: amount.convertedAmount,
      buttons: [.send(.jetton(jettonItem)), .receive(.jetton(jettonItem))]
    )
  }
}
