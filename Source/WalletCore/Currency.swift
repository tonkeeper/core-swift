import Foundation

public enum Currency: String, Codable {
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
    
    func formatter(locale: Locale = Locale.current) -> NumberFormatter {
        let f = NumberFormatter()
        f.locale = locale
        f.currencyCode = self.rawValue
        // TODO: customize TON representation to fit our needs.
        return f
    }
}
