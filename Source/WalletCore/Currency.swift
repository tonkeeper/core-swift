import Foundation

public enum Currency: String, Codable, CaseIterable {
    case TON = "TON"
    case JPY = "JPY"
    case USD = "USD"
    case EUR = "EUR"
    case RUB = "RUB"
    case AED = "AED"
    case KZT = "KZT"
    case UAH = "UAH"
    case GBP = "GBP"
    case CHF = "CHF"
    case CNY = "CNY"
    case KRW = "KRW"
    case IDR = "IDR"
    case INR = "INR"
    
    var code: String {
        self.rawValue
    }
    
    var symbol: String? {
        let localeIds = Locale.availableIdentifiers
        for localeId in localeIds {
            let locale = Locale(identifier: localeId)
            let localeCurrencyCode: String
            if #available(iOS 16, *) {
                localeCurrencyCode = locale.currency?.identifier ?? ""
            } else {
                localeCurrencyCode = locale.currencyCode ?? ""
            }
            if localeCurrencyCode == self.code {
                return locale.currencySymbol
            }
        }
        return nil
    }
    
    func formatter(locale: Locale = Locale.current) -> NumberFormatter {
        let f = NumberFormatter()
        f.locale = locale
        f.currencyCode = self.rawValue
        // TODO: customize TON representation to fit our needs.
        return f
    }
}
