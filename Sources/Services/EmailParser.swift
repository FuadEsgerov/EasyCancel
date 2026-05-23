import Foundation

/// Heuristic parser for subscription-confirmation emails. Mirrors the server-side
/// `parse-email` Edge Function: known-merchant matching + amount/currency/
/// frequency/date heuristics, with a confidence score. The Edge Function calls
/// Mistral when confidence is low; on-device this is the paste-to-autofill path,
/// where the user reviews and corrects anything flagged.
enum EmailParser {

    static func parse(subject: String, body: String, from: String = "") -> ParsedSubscription {
        let haystack = "\(subject)\n\(body)".lowercased()

        let merchant = detectMerchant(from: from, subject: subject, body: body)
        let money = detectAmount(in: "\(subject)\n\(body)")
        let frequency = detectFrequency(in: haystack)
        let signup = detectDate(in: body) ?? detectDate(in: subject)

        var confidence = 0.0
        switch merchant?.source {
        case .known: confidence += 0.30
        case .derived: confidence += 0.15
        case .none: break
        }
        if money != nil { confidence += 0.40 }
        if frequency != nil { confidence += 0.20 }
        if signup != nil { confidence += 0.10 }

        return ParsedSubscription(
            merchantName: merchant?.name,
            amountCents: money?.cents,
            currency: money?.currency,
            billingFrequency: frequency,
            signupDate: signup,
            confidence: min(confidence, 1.0)
        )
    }

    // MARK: - Merchant

    private struct MerchantMatch { let name: String; let source: Source; enum Source { case known, derived } }

    /// keyword (lowercased, matched as substring of domain/name/text) → display name.
    private static let knownMerchants: [(String, String)] = [
        ("netflix", "Netflix"), ("spotify", "Spotify"), ("disney", "Disney+"),
        ("audible", "Audible"), ("youtube", "YouTube Premium"), ("amazon", "Amazon"),
        ("nytimes", "NYT"), ("new york times", "NYT"),
        ("fitnessfirst", "FitnessFirst"), ("fitness first", "FitnessFirst"),
        ("mcfit", "McFit"), ("dazn", "DAZN"), ("adobe", "Adobe"),
        ("dropbox", "Dropbox"), ("notion", "Notion"), ("linkedin", "LinkedIn"),
        ("duolingo", "Duolingo"), ("hellofresh", "HelloFresh"), ("patreon", "Patreon"),
        ("apple", "Apple"), ("google", "Google"), ("microsoft", "Microsoft"),
    ]

    private static func detectMerchant(from: String, subject: String, body: String) -> MerchantMatch? {
        let domain = senderDomain(from)
        let display = senderDisplayName(from)

        // Priority: sender domain/display, then subject, then body.
        let scopes = [domain, display, subject.lowercased(), body.lowercased()]
        for scope in scopes where !scope.isEmpty {
            for (keyword, name) in knownMerchants where scope.contains(keyword) {
                return MerchantMatch(name: name, source: .known)
            }
        }

        // Fall back to the registrable label of the sender domain.
        if let label = registrableLabel(domain) {
            return MerchantMatch(name: label.capitalized, source: .derived)
        }
        return nil
    }

    /// Domain portion of an address like "Netflix <info@netflix.com>".
    private static func senderDomain(_ from: String) -> String {
        guard let at = from.range(of: "@") else { return "" }
        let tail = from[at.upperBound...]
        let domain = tail.prefix { $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" }
        return String(domain).lowercased()
    }

    private static func senderDisplayName(_ from: String) -> String {
        if let lt = from.firstIndex(of: "<") {
            return String(from[..<lt]).trimmingCharacters(in: .whitespaces).lowercased()
        }
        return from.contains("@") ? "" : from.lowercased()
    }

    /// "account.netflix.co.uk" → "netflix" (drops TLD + common 2nd-level + mail subdomains).
    private static func registrableLabel(_ domain: String) -> String? {
        guard !domain.isEmpty else { return nil }
        var labels = domain.split(separator: ".").map(String.init)
        let secondLevel: Set<String> = ["co", "com", "org", "net", "gov", "ac"]
        if labels.count >= 2, secondLevel.contains(labels[labels.count - 2]) {
            labels.removeLast() // TLD like uk
        }
        labels = labels.filter { !["mail", "email", "e", "news", "no-reply", "noreply", "account", "billing", "info", "smtp"].contains($0) }
        guard labels.count >= 2 else { return nil }
        return labels[labels.count - 2]
    }

    // MARK: - Amount + currency

    private struct Money { let cents: Int; let currency: String }

    private static let currencyByToken: [String: String] = [
        "€": "EUR", "eur": "EUR",
        "£": "GBP", "gbp": "GBP",
        "$": "USD", "usd": "USD",
        "zł": "PLN", "zl": "PLN", "pln": "PLN",
    ]

    /// Matches a currency marker adjacent (either side) to a number.
    private static let amountPatterns: [NSRegularExpression] = {
        let symbolsBefore = "€|£|\\$|zł|EUR|GBP|USD|PLN"
        let symbolsAfter = "€|£|zł|EUR|GBP|USD|PLN"
        let number = "\\d[\\d.,]*\\d|\\d"
        return [
            "(\(symbolsBefore))\\s*(\(number))",
            "(\(number))\\s*(\(symbolsAfter))",
        ].compactMap { try? NSRegularExpression(pattern: $0, options: [.caseInsensitive]) }
    }()

    private static let priceKeywords = ["total", "amount", "charged", "billed", "price", "betrag", "montant", "importe", "kwota", "due", "pay"]

    private static func detectAmount(in text: String) -> Money? {
        let ns = text as NSString
        var candidates: [(money: Money, nearKeyword: Bool, location: Int)] = []

        for regex in amountPatterns {
            for m in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                let g1 = ns.substring(with: m.range(at: 1))
                let g2 = ns.substring(with: m.range(at: 2))
                let (token, numberStr) = isCurrencyToken(g1) ? (g1, g2) : (g2, g1)
                guard let currency = currencyByToken[token.lowercased()],
                      let cents = cents(fromAmount: numberStr) else { continue }
                let window = ns.substring(with: NSRange(location: max(0, m.range.location - 24),
                                                        length: min(48, ns.length - max(0, m.range.location - 24)))).lowercased()
                let near = priceKeywords.contains { window.contains($0) }
                candidates.append((Money(cents: cents, currency: currency), near, m.range.location))
            }
        }
        guard !candidates.isEmpty else { return nil }
        // Prefer an amount sitting next to a price keyword; else the largest.
        if let keyed = candidates.filter(\.nearKeyword).max(by: { $0.money.cents < $1.money.cents }) {
            return keyed.money
        }
        return candidates.max(by: { $0.money.cents < $1.money.cents })?.money
    }

    private static func isCurrencyToken(_ s: String) -> Bool {
        currencyByToken[s.lowercased()] != nil
    }

    /// Normalizes "9,99" / "1.234,56" / "1,234.56" / "9.99" → cents.
    static func cents(fromAmount raw: String) -> Int? {
        let s = raw.filter { $0.isNumber || $0 == "." || $0 == "," }
        guard !s.isEmpty else { return nil }

        let lastSep = [s.lastIndex(of: "."), s.lastIndex(of: ",")].compactMap { $0 }.max()
        var integerPart = s
        var fractionPart = "00"
        if let sep = lastSep {
            let after = s[s.index(after: sep)...]
            if after.count == 2, after.allSatisfy(\.isNumber) {
                integerPart = String(s[..<sep])
                fractionPart = String(after)
            }
        }
        let digits = integerPart.filter(\.isNumber)
        guard !digits.isEmpty, let intVal = Int(digits) else { return nil }
        let cents = intVal * 100 + (Int(fractionPart) ?? 0)
        return cents > 0 ? cents : nil
    }

    // MARK: - Frequency

    private static func detectFrequency(in haystack: String) -> Subscription.BillingFrequency? {
        let contains: ([String]) -> Bool = { needles in needles.contains { haystack.contains($0) } }
        if contains(["year", "annual", "jährlich", "pro jahr", "par an", "/an", "anual", "annuel", "annuale", "rocznie"]) {
            return .yearly
        }
        if contains(["quarter", "vierteljähr", "trimestr"]) { return .quarterly }
        if contains(["week", "wöchentlich", "par semaine", "semanal", "settimanal", "tygodnio"]) { return .weekly }
        if contains(["month", "/mo", "monatlich", "im monat", "par mois", "/mois", "al mese", "mensual", "mensile", "miesięcz"]) {
            return .monthly
        }
        return nil
    }

    // MARK: - Date

    private static func detectDate(in text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return nil }
        let ns = text as NSString
        let match = detector.firstMatch(in: text, range: NSRange(location: 0, length: ns.length))
        guard let date = match?.date else { return nil }
        // Ignore implausible far-future detections (e.g. order numbers misread as years).
        return date <= Date().addingTimeInterval(60 * 60 * 24 * 366) ? date : nil
    }
}
