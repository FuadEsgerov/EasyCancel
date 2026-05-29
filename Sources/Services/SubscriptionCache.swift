import Foundation
import SwiftData

/// SwiftData-backed local mirror of the user's subscriptions, so the list shows
/// instantly on launch and stays readable offline (spec §6 "SwiftData cache").
/// It is a *cache*, not the source of truth — Supabase remains authoritative;
/// this is overwritten on every successful fetch.
@Model
final class CachedSubscription {
    @Attribute(.unique) var id: UUID
    var merchantName: String
    var amountCents: Int
    var currency: String
    var billingFrequencyRaw: String
    var signupDate: Date
    var nextRenewalDate: Date?
    var statusRaw: String

    init(from sub: Subscription) {
        self.id = sub.id
        self.merchantName = sub.merchantName
        self.amountCents = sub.amountCents
        self.currency = sub.currency
        self.billingFrequencyRaw = sub.billingFrequency.rawValue
        self.signupDate = sub.signupDate
        self.nextRenewalDate = sub.nextRenewalDate
        self.statusRaw = sub.status.rawValue
    }

    var domain: Subscription? {
        guard let frequency = Subscription.BillingFrequency(rawValue: billingFrequencyRaw),
              let status = Subscription.Status(rawValue: statusRaw) else { return nil }
        return Subscription(
            id: id,
            merchantName: merchantName,
            amountCents: amountCents,
            currency: currency,
            billingFrequency: frequency,
            signupDate: signupDate,
            nextRenewalDate: nextRenewalDate,
            status: status
        )
    }
}

/// Off-main-actor store for the cache. `@ModelActor` gives it its own
/// `ModelContext` isolated to the actor, satisfying Swift 6 strict concurrency.
@ModelActor
actor SubscriptionCache {
    /// All cached subscriptions (order is not guaranteed; the store re-sorts).
    func load() -> [Subscription] {
        let rows = (try? modelContext.fetch(FetchDescriptor<CachedSubscription>())) ?? []
        return rows.compactMap(\.domain)
    }

    /// Replace the entire cache with the latest authoritative set.
    func replace(with subscriptions: [Subscription]) {
        try? modelContext.delete(model: CachedSubscription.self)
        for sub in subscriptions {
            modelContext.insert(CachedSubscription(from: sub))
        }
        try? modelContext.save()
    }

    /// Empty the cache (used on sign-out / account deletion).
    func clear() {
        try? modelContext.delete(model: CachedSubscription.self)
        try? modelContext.save()
    }
}

extension SubscriptionCache {
    /// On-disk cache backed by the app's default store. Returns nil if SwiftData
    /// can't open the store (then the app simply runs without an offline cache).
    static func makeDefault() -> SubscriptionCache? {
        guard let container = try? ModelContainer(for: CachedSubscription.self) else { return nil }
        return SubscriptionCache(modelContainer: container)
    }
}
