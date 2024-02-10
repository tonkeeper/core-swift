import Foundation
import TonSwift
import UIKit.UIImage

public final class ReceiveController {
  public struct Model {
    public enum Image {
      case ton
      case url(URL?)
    }
    
    public let tokenName: String
    public let descriptionTokenName: String
    public let address: String?
    public let image: Image
  }
  
  public var didUpdateModel: ((Model) -> Void)?
  
  private let token: Token
  private let walletsStore: WalletsStore
  
  init(token: Token,
       walletsStore: WalletsStore) {
    self.token = token
    self.walletsStore = walletsStore
  }
  
  public func createModel() {
    let tokenName: String
    let descriptionTokenName: String
    let image: Model.Image
    
    switch token {
    case .ton:
      tokenName = TonInfo.name
      descriptionTokenName = "\(TonInfo.name) \(TonInfo.symbol)"
      image = .ton
    case .jetton(let jettonInfo):
      tokenName = jettonInfo.symbol ?? jettonInfo.name
      descriptionTokenName = jettonInfo.symbol ?? jettonInfo.name
      image = .url(jettonInfo.imageURL)
    }
    
    didUpdateModel?(
      Model(
        tokenName: tokenName,
        descriptionTokenName: descriptionTokenName,
        address: try? walletsStore.activeWallet.address.toString(bounceable: false),
        image: image
      )
    )
  }
}
