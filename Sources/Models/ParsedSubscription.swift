import Foundation

/// Fields extracted from a confirmation email by `EmailParser`. Everything is
/// optional because a parse can be partial; `confidence` (0...1) reflects how
/// much was recovered. Spec F3.3 flags anything below 0.7 for user review.
struct ParsedSubscription: Equatable, Sendable {
    var merchantName: String?
    var amountCents: Int?
    var currency: String?
    var billingFrequency: Subscription.BillingFrequency?
    var signupDate: Date?
    var confidence: Double

    static let reviewThreshold = 0.7

    /// Below the threshold the user should confirm/correct before saving.
    var needsReview: Bool { confidence < Self.reviewThreshold }

    var hasAnything: Bool {
        merchantName != nil || amountCents != nil || billingFrequency != nil
    }

    static let empty = ParsedSubscription(confidence: 0)
}
