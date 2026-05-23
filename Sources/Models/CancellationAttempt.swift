import Foundation

struct CancellationAttempt: Identifiable, Hashable, Sendable {
    let id: UUID
    let subscriptionID: UUID
    var merchantName: String
    var method: Method
    var sentAt: Date
    var outcome: Outcome
    var legalClauseCited: String

    enum Method: String, Codable, Sendable, CaseIterable {
        case button, letterEmail, letterCertified

        var label: String {
            switch self {
            case .button: String(localized: "Cancellation button")
            case .letterEmail: String(localized: "Withdrawal letter (email)")
            case .letterCertified: String(localized: "Certified letter")
            }
        }
    }

    enum Outcome: String, Codable, Sendable {
        case pending, success, rejected, noResponse, disputed

        var label: String {
            switch self {
            case .pending: String(localized: "Awaiting response")
            case .success: String(localized: "Cancelled")
            case .rejected: String(localized: "Rejected")
            case .noResponse: String(localized: "No response")
            case .disputed: String(localized: "Disputed")
            }
        }
    }

    init(
        id: UUID = UUID(),
        subscriptionID: UUID,
        merchantName: String,
        method: Method,
        sentAt: Date = Date(),
        outcome: Outcome = .pending,
        legalClauseCited: String
    ) {
        self.id = id
        self.subscriptionID = subscriptionID
        self.merchantName = merchantName
        self.method = method
        self.sentAt = sentAt
        self.outcome = outcome
        self.legalClauseCited = legalClauseCited
    }
}
