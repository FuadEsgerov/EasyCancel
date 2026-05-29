import WidgetKit
import SwiftUI

/// Home Screen widget showing the subscription whose 14-day cooling-off window
/// closes soonest, plus how many other windows are open. Reads the snapshot the
/// app publishes to the shared App Group.
struct CoolingOffWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CoolingOffWidget", provider: CoolingOffProvider()) { entry in
            CoolingOffWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Cooling-off")
        .description("See your soonest cancellation deadline at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CoolingOffTimelineEntry: TimelineEntry {
    let date: Date
    let entries: [CoolingOffEntry]
    var soonest: CoolingOffEntry? { entries.first }

    static let placeholder = CoolingOffTimelineEntry(
        date: Date(),
        entries: [CoolingOffEntry(
            merchantName: "Netflix", amountFormatted: "€15.99",
            deadline: Calendar.current.date(byAdding: .day, value: 9, to: Date()) ?? Date()
        )]
    )

    static func fromStore() -> CoolingOffTimelineEntry {
        CoolingOffTimelineEntry(date: Date(), entries: CoolingOffSnapshot.read().entries)
    }
}

struct CoolingOffProvider: TimelineProvider {
    func placeholder(in context: Context) -> CoolingOffTimelineEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (CoolingOffTimelineEntry) -> Void) {
        completion(context.isPreview ? .placeholder : .fromStore())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CoolingOffTimelineEntry>) -> Void) {
        let entry = CoolingOffTimelineEntry.fromStore()
        // Refresh at most every 6h, or sooner if a deadline passes before then.
        let cap = Date().addingTimeInterval(6 * 3600)
        let next = min(entry.soonest?.deadline ?? cap, cap)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

private func daysRemaining(until deadline: Date) -> Int {
    let cal = Calendar.current
    let from = cal.startOfDay(for: Date())
    let to = cal.startOfDay(for: deadline)
    return max(0, cal.dateComponents([.day], from: from, to: to).day ?? 0)
}

struct CoolingOffWidgetView: View {
    let entry: CoolingOffTimelineEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let soonest = entry.soonest {
            content(for: soonest)
        } else {
            emptyState
        }
    }

    private func content(for item: CoolingOffEntry) -> some View {
        let days = daysRemaining(until: item.deadline)
        return VStack(alignment: .leading, spacing: 6) {
            Label("Cooling-off", systemImage: "clock.badge.checkmark")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text("\(days)")
                .font(.system(size: family == .systemSmall ? 40 : 48, weight: .bold, design: .rounded))
                .foregroundStyle(.tint)
            Text(days == 1 ? "day left to cancel" : "days left to cancel")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            HStack {
                Text(item.merchantName)
                    .font(.footnote.weight(.medium))
                    .lineLimit(1)
                Spacer()
                if entry.entries.count > 1 {
                    Text("+\(entry.entries.count - 1)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("EasyCancel", systemImage: "checkmark.shield")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text("No open cooling-off windows")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
