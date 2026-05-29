import Testing
import Foundation
import SwiftData
@testable import EasyCancel

@MainActor
struct SubscriptionCacheTests {
    /// Builds an isolated in-memory cache so tests never touch the on-disk store.
    private func makeCache() throws -> SubscriptionCache {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: CachedSubscription.self, configurations: config)
        return SubscriptionCache(modelContainer: container)
    }

    private func sample(_ name: String, status: Subscription.Status = .active) -> Subscription {
        Subscription(
            id: UUID(), merchantName: name, amountCents: 1599, currency: "EUR",
            billingFrequency: .monthly, signupDate: Date(),
            nextRenewalDate: Date().addingTimeInterval(86_400 * 28), status: status
        )
    }

    @Test func replaceThenLoadRoundTrips() async throws {
        let cache = try makeCache()
        let subs = [sample("Netflix"), sample("Spotify", status: .cancelled)]
        await cache.replace(with: subs)

        let loaded = await cache.load()
        #expect(loaded.count == 2)
        #expect(Set(loaded.map(\.merchantName)) == ["Netflix", "Spotify"])
        #expect(loaded.first { $0.merchantName == "Spotify" }?.status == .cancelled)
    }

    @Test func replaceOverwritesPreviousContents() async throws {
        let cache = try makeCache()
        await cache.replace(with: [sample("Netflix"), sample("Spotify")])
        await cache.replace(with: [sample("NYT")])

        let loaded = await cache.load()
        #expect(loaded.count == 1)
        #expect(loaded.first?.merchantName == "NYT")
    }

    @Test func clearEmptiesCache() async throws {
        let cache = try makeCache()
        await cache.replace(with: [sample("Netflix")])
        await cache.clear()
        #expect(await cache.load().isEmpty)
    }
}
