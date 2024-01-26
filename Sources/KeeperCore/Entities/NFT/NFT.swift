import Foundation
import TonSwift

public struct NFT: Codable {
  let address: Address
  let owner: WalletAccount?
  let name: String?
  let imageURL: URL?
  let preview: Preview
  let description: String?
  let attributes: [Attribute]
  let collection: NFTCollection?
  let dns: String?
  let sale: Sale?
  let isHidden: Bool
  
  struct Marketplace {
    let name: String
    let url: URL?
  }
  
  struct Attribute: Codable {
    let key: String
    let value: String
  }
  
  enum Trust {
    struct Approval {
      let name: String
    }
    case approvedBy([Approval])
  }
  
  struct Preview: Codable {
    let size5: URL?
    let size100: URL?
    let size500: URL?
    let size1500: URL?
  }
  
  struct Sale: Codable {
    let address: Address
    let market: WalletAccount
    let owner: WalletAccount?
  }
}

struct NFTCollection: Codable {
  let address: Address
  let name: String?
  let description: String?
}
