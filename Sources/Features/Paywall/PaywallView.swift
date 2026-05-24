import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    private let termsURL = URL(string: "https://vincli.com/docs/easyterms.pdf")!
    private let privacyURL = URL(string: "https://vincli.com/docs/easyprivacy.pdf")!

    private static var isScreenshots: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshots")
    }

    var body: some View {
        NavigationStack {
            Group {
                if Self.isScreenshots {
                    screenshotPaywall
                } else {
                    storeView
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
            }
        }
    }

    // Matches subscriptions by product ID (not group ID) so the same code works
    // against both the local StoreKit config and the real App Store group, whose
    // Apple-assigned group ID differs from the test config's.
    private var storeView: some View {
        SubscriptionStoreView(productIDs: ProProduct.all) {
            marketingContent
        }
        .subscriptionStoreControlStyle(.prominentPicker)
        .subscriptionStoreButtonLabel(.multiline)
        .storeButton(.visible, for: .restorePurchases)
        .subscriptionStorePolicyDestination(url: termsURL, for: .termsOfService)
        .subscriptionStorePolicyDestination(url: privacyURL, for: .privacyPolicy)
        .onInAppPurchaseCompletion { _, result in
            if case .success(.success(.verified(let transaction))) = result {
                await transaction.finish()
                await store.refreshEntitlements()
                dismiss()
            }
        }
    }

    // Static stand-in shown only under `-screenshots` (UI tests have no StoreKit
    // backend) so we can capture an App Store / IAP-review paywall image. Mirrors
    // the real paywall's branding, benefits and pricing.
    private var screenshotPaywall: some View {
        ScrollView {
            VStack(spacing: 24) {
                marketingContent
                VStack(spacing: 12) {
                    planCard(title: "Yearly", price: "€19.99 / year", note: "Best value · Save 44%", highlighted: true)
                    planCard(title: "Monthly", price: "€2.99 / month", note: "7-day free trial", highlighted: false)
                }
                .padding(.horizontal)
                Button {} label: {
                    Text("Subscribe")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                Text("By subscribing you agree to our Terms and Privacy Policy. Cancel anytime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.vertical, 24)
        }
    }

    private func planCard(title: LocalizedStringKey, price: LocalizedStringKey,
                          note: LocalizedStringKey, highlighted: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(note).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(price).font(.body.weight(.semibold))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .stroke(highlighted ? Color.accentColor : Color.secondary.opacity(0.3),
                        lineWidth: highlighted ? 2 : 1)
        )
    }

    private var marketingContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                Text("EasyCancel Pro")
                    .font(.title.bold())
                Text("Cancel any subscription with confidence.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                BenefitRow(
                    symbol: "infinity",
                    title: "Unlimited subscriptions",
                    subtitle: "Track and cancel as many as you need"
                )
                BenefitRow(
                    symbol: "person.2.fill",
                    title: "Family Sharing",
                    subtitle: "Share Pro with your whole family"
                )
                BenefitRow(
                    symbol: "envelope.badge.shield.half.filled",
                    title: "Certified-mail option",
                    subtitle: "Send legally binding registered letters"
                )
            }
        }
        .padding(.top, 24)
    }
}

private struct BenefitRow: View {
    let symbol: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 16))
        layout {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !typeSize.isAccessibilitySize {
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PaywallView()
        .environment(StoreManager())
}
