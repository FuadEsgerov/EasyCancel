import Testing
import Foundation
@testable import EasyCancel

struct SubscriptionTests {
    @Test func coolingOffDeadlineIs14DaysAfterSignup() {
        let signup = Date(timeIntervalSince1970: 0)
        let sub = Subscription(
            id: UUID(),
            merchantName: "Test",
            amountCents: 999,
            currency: "EUR",
            billingFrequency: .monthly,
            signupDate: signup,
            nextRenewalDate: nil,
            status: .active
        )
        let expected = Calendar.current.date(byAdding: .day, value: 14, to: signup)!
        #expect(sub.coolingOffDeadline == expected)
    }
}

@MainActor
struct FreeTierGateTests {
    private func store(activeCount: Int) async -> SubscriptionStore {
        let subs = (0..<activeCount).map { i in
            Subscription(
                id: UUID(), merchantName: "S\(i)", amountCents: 100, currency: "EUR",
                billingFrequency: .monthly, signupDate: .now, nextRenewalDate: nil, status: .active
            )
        }
        let store = SubscriptionStore(service: MockSubscriptionService(subscriptions: subs))
        await store.load()
        return store
    }

    @Test func freeUserCanAddBelowLimit() async {
        let store = await store(activeCount: FreeTier.maxActiveSubscriptions - 1)
        #expect(store.canAddSubscription(isPro: false))
    }

    @Test func freeUserBlockedAtLimit() async {
        let store = await store(activeCount: FreeTier.maxActiveSubscriptions)
        #expect(store.canAddSubscription(isPro: false) == false)
    }

    @Test func proUserUnlimited() async {
        let store = await store(activeCount: FreeTier.maxActiveSubscriptions + 5)
        #expect(store.canAddSubscription(isPro: true))
    }
}
