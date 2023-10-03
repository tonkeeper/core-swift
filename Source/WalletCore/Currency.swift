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
    
    public var code: String {
        self.rawValue
    }
    
    var symbol: String {
        switch self {
        case .TON: return "TON"
        case .USD: return "$"
        case .JPY: return "¥"
        case .AED: return rawValue
        case .EUR: return "€"
        case .CHF: return "₣"
        case .CNY: return "¥"
        case .GBP: return "£"
        case .IDR: return "Rp"
        case .INR: return "₹"
        case .KRW: return "₩"
        case .KZT: return "₸"
        case .RUB: return "₽"
        case .UAH: return "₴"
        }
    }
    
    var symbolOnLeft: Bool {
        switch self {
        case .EUR, .USD, .GBP: return true
        default: return false
        }
    }
}
