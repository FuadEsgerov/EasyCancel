import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// Live Activity describing one subscription's countdown to its 14-day
/// cooling-off deadline. ActivityKit matches the app's `Activity` to the
/// widget's `ActivityConfiguration` by this type's name, so the declaration is
/// compiled into both the app and the widget extension.
struct CoolingOffActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var deadline: Date
        var daysRemaining: Int
    }

    var merchantName: String
}
#endif
