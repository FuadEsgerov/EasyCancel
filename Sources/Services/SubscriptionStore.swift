import Foundation
import Observation

/// App-wide observable state. Injected once at the app root via
/// `.environment(store)` and read by views with
/// `@Environment(SubscriptionStore.self) private var store`.
@MainActor
@Observable
final class SubscriptionStore {
    private(set) var subscriptions: [Subscription] = []
    private(set) var attempts: [CancellationAttempt] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: any SubscriptionService

    /// Called after every load with the current active subscriptions, so the app
    /// can (re)schedule reminders. Set once at the app root.
    var onLoaded: (([Subscription]) -> Void)?

    init(service: any SubscriptionService) {
        self.service = service
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            subscriptions = try await service.fetchSubscriptions()
            attempts = try await service.fetchAttempts()
        } catch {
            errorMessage = error.localizedDescription
        }
        onLoaded?(activeSubscriptions)
    }

    func add(_ subscription: Subscription) async {
        do {
            try await service.add(subscription)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancel(_ subscription: Subscription, method: CancellationAttempt.Method) async {
        do {
            _ = try await service.cancel(subscriptionID: subscription.id, method: method)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Active subscriptions sorted by soonest renewal.
    var activeSubscriptions: [Subscription] {
        subscriptions
            .filter { $0.status == .active }
            .sorted { ($0.nextRenewalDate ?? .distantFuture) < ($1.nextRenewalDate ?? .distantFuture) }
    }

    var totalMonthlyCents: Int {
        subscriptions
            .filter { $0.status == .active }
            .reduce(0) { $0 + $1.monthlyAmountCents }
    }

    var totalMonthlyFormatted: String {
        let currency = subscriptions.first?.currency ?? "EUR"
        return Subscription.formatCurrency(cents: totalMonthlyCents, currency: currency)
    }

    /// Whether a free user may add another subscription. Pro is unlimited;
    /// free is capped at `FreeTier.maxActiveSubscriptions`.
    func canAddSubscription(isPro: Bool) -> Bool {
        isPro || activeSubscriptions.count < FreeTier.maxActiveSubscriptions
    }
}

extension SubscriptionStore {
    /// Preview/test store pre-seeded synchronously (no async load needed).
    static func previewLoaded() -> SubscriptionStore {
        let store = SubscriptionStore(service: MockSubscriptionService())
        store.subscriptions = MockSubscriptionService.sampleData
        store.attempts = []
        return store
    }
}
