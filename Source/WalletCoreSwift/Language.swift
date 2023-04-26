import Foundation

public enum Language: Int, CaseIterable {
    case en, ru

    public static let defaultLanguage: Language = .en
    
    public var localizationSecondaryText: String {
        switch self {
        case .en: return "English"
        case .ru: return "Русский"
        }
    }
    
    public var localizationText: String {
        switch self {
        case .en: return "en"
        case .ru: return "ru"
        }
    }
    
    public init(lang: String) {
        switch lang {
        case "en": self = .en
        case "ru": self = .ru
        default: self = .en
        }
    }
}
