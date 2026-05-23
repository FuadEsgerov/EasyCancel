import Foundation

struct Subscription: Identifiable, Hashable, Sendable {
    let id: UUID
    var merchantName: String
    var amountCents: Int
    var currency: String
    var billingFrequency: BillingFrequency
    var signupDate: Date
    var nextRenewalDate: Date?
    var status: Status

    enum BillingFrequency: String, Codable, CaseIterable, Sendable {
        case weekly, monthly, quarterly, yearly, oneTime
    }

    enum Status: String, Codable, Sendable {
        case active, cancelled, disputed, expired
    }

    /// EU/UK 14-day cooling-off deadline, measured from signup.
    var coolingOffDeadline: Date {
        Calendar.current.date(byAdding: .day, value: 14, to: signupDate) ?? signupDate
    }
}
