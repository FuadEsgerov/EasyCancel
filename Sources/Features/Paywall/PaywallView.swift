import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    private let termsURL = URL(string: "https://easycancel.app/terms")!
    private let privacyURL = URL(string: "https://easycancel.app/privacy")!

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(groupID: ProProduct.groupID) {
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
            }
        }
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
