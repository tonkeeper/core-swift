import Foundation

struct Rates: Codable {
  struct Rate: Codable {
    let currency: Currency
    let rate: Decimal
    let diff24h: String?
  }
  
  struct JettonRate: Codable {
    let jettonInfo: JettonInfo
    var rates: [Rate]
  }
  
  var ton: [Rate]
  var jettonsRates: [JettonRate]
}

