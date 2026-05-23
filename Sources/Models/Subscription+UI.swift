import Foundation

extension Subscription {
    /// Amount normalized to a monthly figure, for totals.
    var monthlyAmountCents: Int {
        switch billingFrequency {
        case .weekly: amountCents * 52 / 12
        case .monthly: amountCents
        case .quarterly: amountCents / 3
        case .yearly: amountCents / 12
        case .oneTime: 0
        }
    }

    var amountFormatted: String {
        Self.formatCurrency(cents: amountCents, currency: currency)
    }

    var monthlyAmountFormatted: String {
        Self.formatCurrency(cents: monthlyAmountCents, currency: currency)
    }

    static func formatCurrency(cents: Int, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: Double(cents) / 100))
            ?? String(format: "%.2f %@", Double(cents) / 100, currency)
    }

    /// Whole days from today (start of day) until the cooling-off deadline.
    /// Negative once the window has closed.
    var daysUntilCoolingOffDeadline: Int {
        let cal = Calendar.current
        let from = cal.startOfDay(for: Date())
        let to = cal.startOfDay(for: coolingOffDeadline)
        return cal.dateComponents([.day], from: from, to: to).day ?? 0
    }

    var isWithinCoolingOff: Bool {
        status == .active && daysUntilCoolingOffDeadline >= 0
    }
}

// MARK: - Localized display labels

extension Subscription.BillingFrequency {
    /// Human-readable, localized frequency, e.g. "Monthly".
    var localizedLabel: String {
        switch self {
        case .weekly:    String(localized: "Weekly")
        case .monthly:   String(localized: "Monthly")
        case .quarterly: String(localized: "Quarterly")
        case .yearly:    String(localized: "Yearly")
        case .oneTime:   String(localized: "One-time")
        }
    }

    /// Short suffix shown after an amount, e.g. "/mo".
    var shortLabel: String {
        switch self {
        case .weekly:    String(localized: "wk")
        case .monthly:   String(localized: "mo")
        case .quarterly: String(localized: "qtr")
        case .yearly:    String(localized: "yr")
        case .oneTime:   ""
        }
    }
}

extension Subscription.Status {
    var localizedLabel: String {
        switch self {
        case .active:    String(localized: "Active")
        case .cancelled: String(localized: "Cancelled")
        case .disputed:  String(localized: "Disputed")
        case .expired:   String(localized: "Expired")
        }
    }
}
