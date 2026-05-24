import Testing
import Foundation
@testable import EasyCancel

struct NotificationPlannerTests {
    private func makeSub(signupDaysAgo: Int = 0,
                         renewalInDays: Int? = nil,
                         status: Subscription.Status = .active,
                         name: String = "Netflix") -> Subscription {
        let cal = Calendar.current
        let now = Date()
        return Subscription(
            id: UUID(),
            merchantName: name,
            amountCents: 1599,
            currency: "EUR",
            billingFrequency: .monthly,
            signupDate: cal.date(byAdding: .day, value: -signupDaysAgo, to: now)!,
            nextRenewalDate: renewalInDays.map { cal.date(byAdding: .day, value: $0, to: now)! },
            status: status
        )
    }

    @Test func schedulesCoolingOffForFreshSubscription() {
        let sub = makeSub(signupDaysAgo: 0)
        let cooling = NotificationPlanner.reminders(for: [sub]).filter { $0.kind == .coolingOff }
        #expect(cooling.count == 1)
        #expect(cooling.first?.id == "cooling-\(sub.id.uuidString)")
        #expect((cooling.first?.fireDate ?? .distantPast) > Date())
    }

    @Test func skipsCoolingOffWhenDeadlinePassed() {
        let sub = makeSub(signupDaysAgo: 20) // 14-day deadline elapsed 6 days ago
        #expect(NotificationPlanner.reminders(for: [sub]).contains { $0.kind == .coolingOff } == false)
    }

    @Test func schedulesRenewalReminder() {
        let sub = makeSub(signupDaysAgo: 0, renewalInDays: 30)
        #expect(NotificationPlanner.reminders(for: [sub])
            .contains { $0.kind == .renewal && $0.id == "renewal-\(sub.id.uuidString)" })
    }

    @Test func ignoresCancelledSubscriptions() {
        let sub = makeSub(signupDaysAgo: 0, renewalInDays: 30, status: .cancelled)
        #expect(NotificationPlanner.reminders(for: [sub]).isEmpty)
    }

    @Test func capsAtMaxReminders() {
        let subs = (0..<50).map { _ in makeSub(signupDaysAgo: 0, renewalInDays: 30) }
        #expect(NotificationPlanner.reminders(for: subs).count <= NotificationPlanner.maxReminders)
    }
}
