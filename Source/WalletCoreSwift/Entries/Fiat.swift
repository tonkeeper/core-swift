import Foundation

public enum FiatCurrencies: String {
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
    case JPY = "JPY"
}

public enum CurrencyStateSide {
    case start, end
}

public protocol CurrencyState {
    var numberFormat: String { get set }
    var symbol: String { get set }
    var side: CurrencyStateSide { get set }
    var maximumFractionDigits: Int { get set }
}

public struct FiatCurrencySymbolsConfig: CurrencyState {
    public var numberFormat: String
    public var symbol: String
    public var side: CurrencyStateSide
    public var maximumFractionDigits: Int
    
    init(currency: FiatCurrencies) {
        switch currency {
        case .USD:
            numberFormat = "en-US"
            symbol = "$"
            side = .start
            maximumFractionDigits = 2
            
        case .EUR:
            numberFormat = "de-DE"
            symbol = "€"
            side = .start
            maximumFractionDigits = 2
            
        case .RUB:
            numberFormat = "ru-RU"
            symbol = "$"
            side = .end
            maximumFractionDigits = 2
            
        case .AED:
            numberFormat = "en-US"
            symbol = "Rp"
            side = .end
            maximumFractionDigits = 2
            
        case .KZT:
            numberFormat = "en-US"
            symbol = "₸"
            side = .end
            maximumFractionDigits = 2
            
        case .UAH:
            numberFormat = "en-US"
            symbol = "₴"
            side = .end
            maximumFractionDigits = 2
            
        case .GBP:
            numberFormat = "en-GB"
            symbol = "£"
            side = .start
            maximumFractionDigits = 2
            
        case .CHF:
            numberFormat = "en-US"
            symbol = "₣"
            side = .start
            maximumFractionDigits = 2
            
        case .CNY:
            numberFormat = "en-US"
            symbol = "¥"
            side = .start
            maximumFractionDigits = 2
            
        case .KRW:
            numberFormat = "en-US"
            symbol = "₩"
            side = .start
            maximumFractionDigits = 0
            
        case .IDR:
            numberFormat = "en-US"
            symbol = "Rp"
            side = .end
            maximumFractionDigits = 2
            
        case .INR:
            numberFormat = "en-US"
            symbol = "₹"
            side = .start
            maximumFractionDigits = 2
            
        case .JPY:
            numberFormat = "ja-JP"
            symbol = "¥"
            side = .start
            maximumFractionDigits = 2
        }
    }
}
