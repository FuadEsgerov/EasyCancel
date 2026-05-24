import SwiftUI

struct HomeView: View {
    @Environment(SubscriptionStore.self) private var store
    @Environment(StoreManager.self) private var storeManager
    @State private var showingAddSheet = false
    @State private var showingForwardSheet = false
    @State private var showingPaywall = false
    @State private var showingLimitAlert = false
    @ScaledMetric(relativeTo: .largeTitle) private var spendSize: CGFloat = 36

    private var canAdd: Bool {
        store.canAddSubscription(isPro: storeManager.isPro)
    }

    private func startForward() {
        if canAdd { showingForwardSheet = true } else { showingLimitAlert = true }
    }

    private func startManual() {
        if canAdd { showingAddSheet = true } else { showingLimitAlert = true }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.activeSubscriptions.isEmpty {
                    emptyState
                } else {
                    subscriptionList
                }
            }
            .navigationTitle("EasyCancel")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if FeatureFlags.emailForwardingEnabled {
                        Menu {
                            Button {
                                startForward()
                            } label: {
                                Label("Forward an email", systemImage: "envelope")
                            }
                            Button {
                                startManual()
                            } label: {
                                Label("Enter manually", systemImage: "square.and.pencil")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add subscription")
                    } else {
                        Button {
                            startManual()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add subscription")
                    }
                }
            }
            .navigationDestination(for: Subscription.self) { subscription in
                SubscriptionDetailView(subscription: subscription)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSubscriptionView()
            }
            .sheet(isPresented: $showingForwardSheet) {
                ForwardEmailView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .alert("Free plan limit reached", isPresented: $showingLimitAlert) {
                Button("Upgrade to Pro") { showingPaywall = true }
                Button("Not now", role: .cancel) {}
            } message: {
                Text("You're tracking \(FreeTier.maxActiveSubscriptions) subscriptions on the free plan. Upgrade to Pro for unlimited tracking and Family Sharing.")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No subscriptions yet", systemImage: "creditcard")
        } description: {
            Text("Add your first subscription to start tracking cooling-off deadlines.")
        } actions: {
            Button("Enter manually") {
                startManual()
            }
            .buttonStyle(.borderedProminent)

            if FeatureFlags.emailForwardingEnabled {
                Button("Forward an email") {
                    startForward()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var subscriptionList: some View {
        List {
            Section {
                spendHeader
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section {
                ForEach(store.activeSubscriptions) { subscription in
                    NavigationLink(value: subscription) {
                        SubscriptionRow(subscription: subscription)
                    }
                    .accessibilityIdentifier(subscription.merchantName)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var spendHeader: some View {
        VStack(spacing: 4) {
            Text(store.totalMonthlyFormatted)
                .font(.system(size: spendSize, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.primary)
            Text("Active monthly spend")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

private struct SubscriptionRow: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 12) {
            leadingIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.merchantName)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(secondaryLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            statusBadge
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var leadingIcon: some View {
        Image(systemName: iconName)
            .font(.title3)
            .foregroundStyle(.tint)
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)
    }

    private var iconName: String {
        switch subscription.billingFrequency {
        case .weekly:   return "repeat.circle"
        case .monthly:  return "calendar.circle"
        case .quarterly: return "calendar.circle.fill"
        case .yearly:   return "star.circle"
        case .oneTime:  return "creditcard.circle"
        }
    }

    private var secondaryLine: String {
        "\(subscription.amountFormatted) · \(subscription.billingFrequency.localizedLabel)"
    }

    @ViewBuilder
    private var statusBadge: some View {
        if subscription.isWithinCoolingOff {
            Text("\(subscription.daysUntilCoolingOffDeadline)d to cancel")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .foregroundStyle(Color.orange)
                .clipShape(Capsule())
        } else if let renewal = subscription.nextRenewalDate {
            let days = Calendar.current.dateComponents([.day], from: .now, to: renewal).day ?? 0
            Text("renews in \(max(days, 0))d")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HomeView()
        .environment(SubscriptionStore.previewLoaded())
        .environment(StoreManager())
}
