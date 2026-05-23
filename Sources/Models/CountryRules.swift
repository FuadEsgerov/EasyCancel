import Foundation

/// Per-country consumer-law parameters used to compute deadlines and cite the
/// correct withdrawal clause in cancellation letters.
struct CountryRules: Sendable, Hashable {
    let countryCode: String
    let coolingOffDays: Int
    let legalCitation: String

    static let all: [String: CountryRules] = [
        "DE": .init(countryCode: "DE", coolingOffDays: 14, legalCitation: "§ 355 BGB"),
        "UK": .init(countryCode: "UK", coolingOffDays: 14, legalCitation: "Consumer Contracts Regulations 2013, Reg. 29"),
        "FR": .init(countryCode: "FR", coolingOffDays: 14, legalCitation: "Article L221-18 du Code de la consommation"),
        "ES": .init(countryCode: "ES", coolingOffDays: 14, legalCitation: "Real Decreto Legislativo 1/2007, Art. 102"),
        "IT": .init(countryCode: "IT", coolingOffDays: 14, legalCitation: "Codice del Consumo, Art. 52"),
        "NL": .init(countryCode: "NL", coolingOffDays: 14, legalCitation: "Burgerlijk Wetboek, Art. 6:230o"),
        "PL": .init(countryCode: "PL", coolingOffDays: 14, legalCitation: "Ustawa o prawach konsumenta, Art. 27"),
    ]

    static func rules(for code: String) -> CountryRules {
        all[code] ?? all["UK"]!
    }
}
