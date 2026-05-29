import WidgetKit
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit

/// Lock Screen banner + Dynamic Island for the cooling-off countdown.
struct CoolingOffLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CoolingOffActivityAttributes.self) { context in
            lockScreen(context)
                .activityBackgroundTint(Color.black.opacity(0.6))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.merchantName, systemImage: "clock.badge.checkmark")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.daysRemaining)d")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.tint)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Cancel free before \(context.state.deadline, format: .dateTime.day().month())")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "clock.badge.checkmark")
            } compactTrailing: {
                Text("\(context.state.daysRemaining)d")
                    .font(.caption2.weight(.bold))
            } minimal: {
                Text("\(context.state.daysRemaining)")
                    .font(.caption2.weight(.bold))
            }
            .keylineTint(.green)
        }
    }

    private func lockScreen(_ context: ActivityViewContext<CoolingOffActivityAttributes>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "clock.badge.checkmark")
                .font(.title2)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.merchantName)
                    .font(.headline)
                Text("Cancel free before \(context.state.deadline, format: .dateTime.weekday().day().month())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 0) {
                Text("\(context.state.daysRemaining)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text("days")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
#endif
