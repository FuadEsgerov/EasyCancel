import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// Starts / updates / ends the cooling-off Live Activity. We keep at most one
/// activity alive — the subscription whose cooling-off window closes soonest —
/// so the Lock Screen / Dynamic Island isn't spammed.
enum LiveActivityController {
    /// Sendable description of the activity we want on screen (or nil = none).
    private struct Target: Sendable {
        let merchantName: String
        let deadline: Date
        let daysRemaining: Int
    }

    static func sync(with subscriptions: [Subscription]) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let soonest = subscriptions
            .filter(\.isWithinCoolingOff)
            .sorted { $0.coolingOffDeadline < $1.coolingOffDeadline }
            .first
        let target = soonest.map {
            Target(merchantName: $0.merchantName,
                   deadline: $0.coolingOffDeadline,
                   daysRemaining: $0.daysUntilCoolingOffDeadline)
        }
        Task { await apply(target) }
    }

    private static func apply(_ target: Target?) async {
        // End any activity that no longer matches the soonest window.
        for activity in Activity<CoolingOffActivityAttributes>.activities
        where target == nil || activity.attributes.merchantName != target?.merchantName {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        guard let target else { return }
        let state = CoolingOffActivityAttributes.ContentState(
            deadline: target.deadline,
            daysRemaining: target.daysRemaining
        )
        let content = ActivityContent(state: state, staleDate: target.deadline)

        if let existing = Activity<CoolingOffActivityAttributes>.activities
            .first(where: { $0.attributes.merchantName == target.merchantName }) {
            await existing.update(content)
        } else {
            _ = try? Activity.request(
                attributes: CoolingOffActivityAttributes(merchantName: target.merchantName),
                content: content
            )
        }
    }
}
#endif
