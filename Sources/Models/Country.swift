import Foundation

/// A supported launch market. The chosen country drives the legal framework
/// (via `CountryRules`) and the default UI language.
struct Country: Identifiable, Hashable, Sendable {
    let code: String          // EasyCancel internal code, e.g. "DE", "UK"
    let name: String          // English display name
    let flag: String          // emoji flag
    let languageCode: String  // default UI language, e.g. "de"

    var id: String { code }

    var rules: CountryRules { CountryRules.rules(for: code) }

    /// Country name localized by the OS into the current UI language.
    /// Falls back to the English `name` if the OS has no localization.
    var localizedName: String {
        let regionCode = (code == "UK") ? "GB" : code
        return Locale.current.localizedString(forRegionCode: regionCode) ?? name
    }

    /// Launch markets (V1.0). Order is roughly by market priority.
    static let supported: [Country] = [
        .init(code: "UK", name: "United Kingdom", flag: "🇬🇧", languageCode: "en"),
        .init(code: "DE", name: "Germany", flag: "🇩🇪", languageCode: "de"),
        .init(code: "FR", name: "France", flag: "🇫🇷", languageCode: "fr"),
        .init(code: "ES", name: "Spain", flag: "🇪🇸", languageCode: "es"),
        .init(code: "IT", name: "Italy", flag: "🇮🇹", languageCode: "it"),
        .init(code: "NL", name: "Netherlands", flag: "🇳🇱", languageCode: "nl"),
        .init(code: "PL", name: "Poland", flag: "🇵🇱", languageCode: "pl"),
    ]

    static func country(for code: String) -> Country {
        supported.first { $0.code == code } ?? supported[0]
    }

    /// Best-guess market from the device locale; falls back to UK.
    static func detected(from locale: Locale = .current) -> Country {
        guard let region = locale.region?.identifier else { return supported[0] }
        // Apple uses ISO region "GB" for the UK; map it to our "UK" code.
        let normalized = (region == "GB") ? "UK" : region
        return supported.first { $0.code == normalized } ?? supported[0]
    }
}
