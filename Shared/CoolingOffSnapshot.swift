import Foundation

/// Shared App Group used to hand the cooling-off snapshot from the app to the
/// widget extension. Must be registered on BOTH App IDs in the Apple Developer
/// portal for device/TestFlight builds (it works in the simulator without it).
enum AppGroup {
    static let id = "group.com.vincli.easycancel"
    static let snapshotKey = "coolingOff.snapshot"
}

/// One subscription still inside its 14-day cooling-off window.
struct CoolingOffEntry: Codable, Hashable {
    let merchantName: String
    let amountFormatted: String
    let deadline: Date
}

/// What the app publishes for the widget to render. Self-contained (no app
/// model types) so the widget target stays decoupled from the app.
struct CoolingOffSnapshot: Codable {
    var entries: [CoolingOffEntry]   // soonest deadline first
    var generatedAt: Date

    static let empty = CoolingOffSnapshot(entries: [], generatedAt: .distantPast)
}

extension CoolingOffSnapshot {
    /// Read the latest snapshot the app wrote (empty if none / unreadable).
    static func read() -> CoolingOffSnapshot {
        guard let defaults = UserDefaults(suiteName: AppGroup.id),
              let data = defaults.data(forKey: AppGroup.snapshotKey),
              let snapshot = try? JSONDecoder().decode(CoolingOffSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }

    /// Persist to the shared container for the widget to pick up.
    func write() {
        guard let defaults = UserDefaults(suiteName: AppGroup.id),
              let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: AppGroup.snapshotKey)
    }
}
