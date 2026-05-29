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
    /// True when the last refresh failed but we're showing cached data instead.
    private(set) var isShowingCachedData = false
    var errorMessage: String?

    private let service: any SubscriptionService
    private let cache: SubscriptionCache?

    /// Called after every load with the current active subscriptions, so the app
    /// can (re)schedule reminders. Set once at the app root.
    var onLoaded: (([Subscription]) -> Void)?

    init(service: any SubscriptionService, cache: SubscriptionCache? = nil) {
        self.service = service
        self.cache = cache
    }

    /// Offline-first load: paint cached data immediately, then refresh from the
    /// backend. On a network failure we keep the cached data rather than blanking
    /// the list, and only surface an error if there's nothing to show.
    func load() async {
        isLoading = true
        defer { isLoading = false }

        if subscriptions.isEmpty, let cache {
            let cached = await cache.load()
            if !cached.isEmpty { subscriptions = cached }
        }

        do {
            let fetched = try await service.fetchSubscriptions()
            subscriptions = fetched
            attempts = try await service.fetchAttempts()
            errorMessage = nil
            isShowingCachedData = false
            if let cache { await cache.replace(with: fetched) }
        } catch {
            // Keep whatever we already have (cache or prior fetch); only error
            // out when we have nothing at all to display.
            if subscriptions.isEmpty {
                errorMessage = error.localizedDescription
            } else {
                isShowingCachedData = true
            }
        }
        onLoaded?(activeSubscriptions)
    }

    /// Drops the local cache (call on sign-out / account deletion).
    func clearCache() async {
        await cache?.clear()
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
