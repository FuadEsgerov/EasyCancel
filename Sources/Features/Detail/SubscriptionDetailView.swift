import SwiftUI

struct SubscriptionDetailView: View {
    @Environment(SubscriptionStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let subscriptionID: UUID
    private let fallback: Subscription

    init(subscription: Subscription) {
        self.subscriptionID = subscription.id
        self.fallback = subscription
    }

    private var current: Subscription {
        store.subscriptions.first { $0.id == subscriptionID } ?? fallback
    }

    @State private var showCancelSheet = false
    @ScaledMetric(relativeTo: .largeTitle) private var amountSize: CGFloat = 40

    var body: some View {
        List {
            heroSection
            if current.isWithinCoolingOff {
                coolingOffCard
            }
            detailSection
            actionSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(current.merchantName)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCancelSheet) {
            CancelConfirmationView(subscription: current)
        }
    }

    private var heroSection: some View {
        Section {
            VStack(spacing: 6) {
                Text(current.amountFormatted)
                    .font(.system(size: amountSize, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(.primary)
                Text(current.billingFrequency.localizedLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    @ViewBuilder
    private var coolingOffCard: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cooling-off window active")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Text("\(current.daysUntilCoolingOffDeadline) days left to cancel under your withdrawal right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
        }
        .listRowBackground(Color.orange.opacity(0.1))
    }

    private var detailSection: some View {
        Section("Details") {
            LabeledContent("Status") {
                statusLabel
            }
            if let renewal = current.nextRenewalDate {
                LabeledContent("Next renewal", value: renewal.formatted(date: .abbreviated, time: .omitted))
            }
            LabeledContent("Billing", value: current.billingFrequency.localizedLabel)
            LabeledContent("Signed up", value: current.signupDate.formatted(date: .abbreviated, time: .omitted))
            LabeledContent("Cooling-off deadline", value: current.coolingOffDeadline.formatted(date: .abbreviated, time: .omitted))
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        Section {
            if current.status == .active {
                Button(role: .destructive) {
                    showCancelSheet = true
                } label: {
                    Label("Cancel now", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .font(.body.weight(.semibold))
                }
                .listRowBackground(Color.red.opacity(0.1))
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cancellation requested")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.green)
                        Text("Your request has been submitted.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var statusLabel: some View {
        let color: Color = switch current.status {
        case .active:    .green
        case .cancelled: .secondary
        case .disputed:  .orange
        case .expired:   .secondary
        }
        return Text(current.status.localizedLabel)
            .foregroundStyle(color)
            .fontWeight(.medium)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var store = SubscriptionStore.previewLoaded()
        var body: some View {
            NavigationStack {
                if let first = store.subscriptions.first {
                    SubscriptionDetailView(subscription: first)
                        .environment(store)
                }
            }
        }
    }
    return PreviewWrapper()
}
