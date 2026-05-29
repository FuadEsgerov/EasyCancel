import Foundation
import WidgetKit

/// App-side publisher: turns the loaded subscriptions into a `CoolingOffSnapshot`
/// in the shared App Group and asks WidgetKit to refresh. Called from the app
/// root whenever subscriptions reload.
enum WidgetBridge {
    static func update(with subscriptions: [Subscription]) {
        let entries = subscriptions
            .filter(\.isWithinCoolingOff)
            .sorted { $0.coolingOffDeadline < $1.coolingOffDeadline }
            .map {
                CoolingOffEntry(
                    merchantName: $0.merchantName,
                    amountFormatted: $0.amountFormatted,
                    deadline: $0.coolingOffDeadline
                )
            }
        CoolingOffSnapshot(entries: entries, generatedAt: Date()).write()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
