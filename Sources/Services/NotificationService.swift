import Foundation
import Observation
import UserNotifications

/// A single scheduled reminder. Pure value type so the scheduling decisions are
/// unit-testable without touching `UNUserNotificationCenter`.
struct PlannedReminder: Equatable, Sendable {
    enum Kind: String, Sendable { case coolingOff, renewal }
    let id: String
    let kind: Kind
    let fireDate: Date
    let title: String
    let body: String
}

/// Pure logic that turns subscriptions into reminders. No side effects.
enum NotificationPlanner {
    /// How many days before a deadline/renewal to remind the user.
    static let leadDays = 2
    /// iOS allows max 64 pending local notifications per app; stay well under.
    static let maxReminders = 60
    /// Local hour of day to fire reminders.
    static let fireHour = 10

    static func reminders(for subscriptions: [Subscription],
                          now: Date = .now,
                          calendar: Calendar = .current) -> [PlannedReminder] {
        var out: [PlannedReminder] = []
        for sub in subscriptions where sub.status == .active {
            if let fire = leadFireDate(before: sub.coolingOffDeadline, now: now, calendar: calendar) {
                out.append(PlannedReminder(
                    id: "cooling-\(sub.id.uuidString)",
                    kind: .coolingOff,
                    fireDate: fire,
                    title: String(localized: "Cancel window closing"),
                    body: String(localized: "Your right to cancel \(sub.merchantName) ends soon.")
                ))
            }
            if let renewal = sub.nextRenewalDate,
               let fire = leadFireDate(before: renewal, now: now, calendar: calendar) {
                out.append(PlannedReminder(
                    id: "renewal-\(sub.id.uuidString)",
                    kind: .renewal,
                    fireDate: fire,
                    title: String(localized: "Upcoming renewal"),
                    body: String(localized: "\(sub.merchantName) renews soon (\(sub.amountFormatted)).")
                ))
            }
        }
        return Array(out.sorted { $0.fireDate < $1.fireDate }.prefix(maxReminders))
    }

    /// Fire date `leadDays` before `date`, at `fireHour` local time. Nil if that
    /// moment is already in the past (we don't remind about elapsed deadlines).
    static func leadFireDate(before date: Date, now: Date, calendar: Calendar) -> Date? {
        guard let lead = calendar.date(byAdding: .day, value: -leadDays, to: date) else { return nil }
        var comps = calendar.dateComponents([.year, .month, .day], from: lead)
        comps.hour = fireHour
        guard let fire = calendar.date(from: comps) else { return nil }
        return fire > now ? fire : nil
    }
}

/// Schedules on-device reminders for cooling-off deadlines and renewals.
/// Injected via `.environment` and driven by `SubscriptionStore.onLoaded`.
@MainActor
@Observable
final class NotificationService {
    private let center = UNUserNotificationCenter.current()
    private let defaults: UserDefaults
    private enum Keys { static let enabled = "reminders.enabled" }

    /// User-facing on/off. Persisted; defaults to on (system permission is separate).
    var remindersEnabled: Bool {
        didSet {
            defaults.set(remindersEnabled, forKey: Keys.enabled)
            if !remindersEnabled { Task { await cancelAll() } }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.remindersEnabled = defaults.object(forKey: Keys.enabled) as? Bool ?? true
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Clears existing reminders and schedules fresh ones. Requests permission
    /// the first time there's actually something to remind about.
    func reschedule(for subscriptions: [Subscription], now: Date = .now) async {
        guard remindersEnabled else { await cancelAll(); return }

        let plan = NotificationPlanner.reminders(for: subscriptions, now: now)
        switch await authorizationStatus() {
        case .notDetermined:
            guard !plan.isEmpty, await requestAuthorization() else { return }
        case .authorized, .provisional:
            break
        default:
            return
        }

        await cancelAll()
        for reminder in plan {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: reminder.fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }
}
