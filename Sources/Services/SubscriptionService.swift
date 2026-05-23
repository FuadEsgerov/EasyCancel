import Foundation

/// Abstraction over the backend (Supabase in production). The app talks only to
/// this protocol; swap `MockSubscriptionService` for a real Supabase-backed
/// implementation once project URL + keys are configured.
protocol SubscriptionService: Sendable {
    func fetchSubscriptions() async throws -> [Subscription]
    func fetchAttempts() async throws -> [CancellationAttempt]
    func add(_ subscription: Subscription) async throws
    func cancel(subscriptionID: UUID, method: CancellationAttempt.Method) async throws -> CancellationAttempt
}

/// In-memory mock with seeded sample data. No network, safe for previews/tests.
actor MockSubscriptionService: SubscriptionService {
    private var subscriptions: [Subscription]
    private var attempts: [CancellationAttempt]

    init(
        subscriptions: [Subscription] = MockSubscriptionService.sampleData,
        attempts: [CancellationAttempt] = []
    ) {
        self.subscriptions = subscriptions
        self.attempts = attempts
    }

    func fetchSubscriptions() async throws -> [Subscription] { subscriptions }

    func fetchAttempts() async throws -> [CancellationAttempt] { attempts }

    func add(_ subscription: Subscription) async throws {
        subscriptions.append(subscription)
    }

    func cancel(subscriptionID: UUID, method: CancellationAttempt.Method) async throws -> CancellationAttempt {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscriptionID }) else {
            throw ServiceError.notFound
        }
        subscriptions[index].status = .cancelled
        let sub = subscriptions[index]
        let attempt = CancellationAttempt(
            subscriptionID: sub.id,
            merchantName: sub.merchantName,
            method: method,
            outcome: .pending,
            legalClauseCited: CountryRules.rules(for: "UK").legalCitation
        )
        attempts.insert(attempt, at: 0)
        return attempt
    }

    enum ServiceError: LocalizedError {
        case notFound
        var errorDescription: String? {
            switch self {
            case .notFound: String(localized: "Subscription not found.")
            }
        }
    }

    static let sampleData: [Subscription] = {
        func daysAgo(_ d: Int) -> Date { Calendar.current.date(byAdding: .day, value: -d, to: Date()) ?? Date() }
        func daysAhead(_ d: Int) -> Date { Calendar.current.date(byAdding: .day, value: d, to: Date()) ?? Date() }
        return [
            Subscription(id: UUID(), merchantName: "Netflix", amountCents: 1599, currency: "EUR",
                         billingFrequency: .monthly, signupDate: daysAgo(2), nextRenewalDate: daysAhead(28), status: .active),
            Subscription(id: UUID(), merchantName: "FitnessFirst", amountCents: 2999, currency: "EUR",
                         billingFrequency: .monthly, signupDate: daysAgo(1), nextRenewalDate: daysAhead(29), status: .active),
            Subscription(id: UUID(), merchantName: "Spotify", amountCents: 1099, currency: "EUR",
                         billingFrequency: .monthly, signupDate: daysAgo(40), nextRenewalDate: daysAhead(5), status: .active),
            Subscription(id: UUID(), merchantName: "NYT", amountCents: 7500, currency: "EUR",
                         billingFrequency: .yearly, signupDate: daysAgo(200), nextRenewalDate: daysAhead(165), status: .active),
        ]
    }()
}
